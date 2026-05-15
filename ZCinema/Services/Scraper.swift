import Foundation
import SwiftSoup

// MARK: - Scraper errors
enum ScraperError: LocalizedError {
    case badURL, network, parse, noStream
    var errorDescription: String? {
        switch self {
        case .badURL:   return "رابط غير صحيح"
        case .network:  return "خطأ في الاتصال"
        case .parse:    return "تعذّر تحليل الصفحة"
        case .noStream: return "لم يُعثر على رابط مشاهدة"
        }
    }
}

// MARK: - Scraper
actor Scraper {
    static let shared = Scraper()
    private let base = "https://egibest.ws"

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 25
        cfg.timeoutIntervalForResource = 45
        cfg.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept-Language": "ar,en;q=0.9",
            "Referer": "https://egibest.ws/"
        ]
        return URLSession(configuration: cfg)
    }()

    // ─── Fetch raw HTML ───────────────────────────────────────────
    func html(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else { throw ScraperError.badURL }
        let (data, _) = try await session.data(from: url)
        guard let str = String(data: data, encoding: .utf8)
                     ?? String(data: data, encoding: .isoLatin1)
        else { throw ScraperError.parse }
        return str
    }

    // ─── Home sections ────────────────────────────────────────────
    func fetchHome() async throws -> [HomeSection] {
        let raw = try await html(from: base)
        let doc = try SwiftSoup.parse(raw)
        var sections: [HomeSection] = []
        var seenTitles = Set<String>()

        for block in try doc.select(".pageContent").array() {
            let titleEl = try? block.select(".mainTitle").first()
            let title = (try? titleEl?.ownText())?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty, !seenTitles.contains(title) else { continue }
            seenTitles.insert(title)

            let items = (try? parseCards(block)) ?? []
            guard !items.isEmpty else { continue }
            sections.append(HomeSection(title: title, items: items))
        }
        return sections
    }

    // ─── Category list (paginated) ────────────────────────────────
    func fetchList(type: MediaType, page: Int = 1) async throws -> [MediaItem] {
        var urlStr = type.pageURL
        if page > 1 { urlStr += "page/\(page)/" }
        let raw = try await html(from: urlStr)
        let doc = try SwiftSoup.parse(raw)
        return (try? parseCards(doc)) ?? []
    }

    // ─── Search ───────────────────────────────────────────────────
    func search(query: String) async throws -> [MediaItem] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let raw = try await html(from: "\(base)/?s=\(q)")
        let doc = try SwiftSoup.parse(raw)
        return (try? parseCards(doc)) ?? []
    }

    // ─── Detail page ──────────────────────────────────────────────
    func fetchDetail(url: String) async throws -> MediaItem {
        let raw = try await html(from: url)
        return try parseDetail(raw: raw, pageURL: url)
    }

    // ─── Episode page (returns servers only) ─────────────────────
    func fetchServers(url: String) async throws -> [StreamServer] {
        let raw = try await html(from: url)
        let doc = try SwiftSoup.parse(raw)
        return parseServers(doc: doc)
    }

    // =========================================================
    // MARK: - Private parsers
    // =========================================================

    // ─── Cards (generic) ─────────────────────────────────────────
    private func parseCards(_ root: Any) throws -> [MediaItem] {
        let elements: Elements
        if let doc = root as? Document {
            elements = try doc.select(".postBlock, .postBlockCol")
        } else if let el = root as? Element {
            elements = try el.select(".postBlock, .postBlockCol")
        } else { return [] }

        var seen = Set<String>()
        var items: [MediaItem] = []
        for el in elements.array() {
            guard let item = try? parseCard(el), !seen.contains(item.pageURL) else { continue }
            seen.insert(item.pageURL)
            items.append(item)
        }
        return items
    }

    private func parseCard(_ el: Element) throws -> MediaItem {
        let href  = (try? el.attr("href")) ?? ""
        let title = ((try? el.attr("title")) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        // image: prefer data-img / data-src over src (lazy-load)
        let img = el.children().first(where: { (try? $0.tagName()) == "div" })
        let imgEl = (try? img?.select("img").first()) ?? (try? el.select("img").first())
        let poster = firstNonEmpty(
            try? imgEl?.attr("data-img"),
            try? imgEl?.attr("data-src"),
            try? imgEl?.attr("src")
        ) ?? ""

        let rating = ((try? el.select(".rating i").first()?.text()) ?? "").trimmingCharacters(in: .whitespaces)
        let fullURL = href.hasPrefix("http") ? href : "\(base)\(href)"
        let type = detectType(url: fullURL, title: title)

        return MediaItem(title: title, posterURL: poster, rating: rating, pageURL: fullURL, type: type)
    }

    // ─── Detail page ─────────────────────────────────────────────
    private func parseDetail(raw: String, pageURL: String) throws -> MediaItem {
        let doc = try SwiftSoup.parse(raw)

        let title = ((try? doc.select(".postTitle h1").first()?.text()) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let imgEl = try? doc.select(".postImg img").first()
        let poster = firstNonEmpty(
            try? imgEl?.attr("data-src"),
            try? imgEl?.attr("src")
        ) ?? ""

        let overview = ((try? doc.select("p.description").first()?.text()) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // meta table
        var year = "", quality = "", country = "", language = ""
        var genres: [String] = []
        for row in (try? doc.select(".postTable tr").array()) ?? [] {
            let cells = (try? row.select("td").array()) ?? []
            guard cells.count >= 2 else { continue }
            let label = (try? cells[0].text()) ?? ""
            let value = (try? cells[1].text()) ?? ""
            if label.contains("سنة")    { year     = value }
            if label.contains("الجودة") { quality  = value }
            if label.contains("الدولة") { country  = value }
            if label.contains("اللغة")  { language = value }
            if label.contains("النوع")  {
                genres = ((try? cells[1].select("a").array().map { (try? $0.text()) ?? "" }) ?? [])
                    .filter { !$0.isEmpty }
            }
        }

        let rating = ((try? doc.select(".postRating").first()?.text()) ?? "")
            .trimmingCharacters(in: .whitespaces)

        let type = detectType(url: pageURL, title: title)
        let servers = parseServers(doc: doc)
        let seasons = parseSeasons(doc: doc, pageURL: pageURL, servers: servers, type: type)

        return MediaItem(
            title:    title,
            posterURL: poster,
            rating:   rating,
            pageURL:  pageURL,
            year:     year,
            type:     type,
            quality:  quality,
            genres:   genres,
            country:  country,
            language: language,
            overview: overview,
            seasons:  seasons
        )
    }

    // ─── Servers ─────────────────────────────────────────────────
    func parseServers(doc: Document) -> [StreamServer] {
        var servers: [StreamServer] = []

        // From #watch-servers-list li  onclick="loadIframe(this,'URL')"
        if let list = try? doc.select("#watch-servers-list li") {
            for (i, li) in list.array().enumerated() {
                let onclick = (try? li.attr("onclick")) ?? ""
                let name    = ((try? li.ownText()) ?? "سيرفر \(i+1)")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let payload = extractLoadIframeURL(onclick) {
                    let encoded = extractAfterURLParam(payload)
                    servers.append(StreamServer(name: name.isEmpty ? "سيرفر \(i+1)" : name,
                                                encodedPayload: encoded))
                }
            }
        }

        // Fallback: scan JS for downloadLinks object
        if servers.isEmpty {
            if let scripts = try? doc.select("script").array() {
                for script in scripts {
                    let js = (try? script.html()) ?? ""
                    if js.contains("downloadLinks") || js.contains("loadIframe") {
                        let extras = extractJSServers(js: js)
                        servers.append(contentsOf: extras)
                    }
                }
            }
        }

        return servers
    }

    // ─── Seasons / Episodes ──────────────────────────────────────
    private func parseSeasons(doc: Document, pageURL: String,
                               servers: [StreamServer], type: MediaType) -> [Season] {
        // For movies or single content: wrap in one pseudo-season
        if type == .movie || (try? doc.select(".all-episodes").first()) == nil {
            if !servers.isEmpty {
                let ep = Episode(number: 1, title: "مشاهدة", pageURL: pageURL, servers: servers)
                return [Season(number: 1, title: "المحتوى", episodes: [ep])]
            }
            return []
        }

        // Series/anime: parse episode links
        var episodes: [Episode] = []
        let links = (try? doc.select(".all-episodes m a, .all-episodes a").array()) ?? []
        for (i, a) in links.enumerated() {
            let href  = (try? a.attr("href")) ?? ""
            let text  = ((try? a.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let num   = extractNumber(text) ?? (links.count - i)
            let epURL = href.hasPrefix("http") ? href : "\(base)\(href)"
            episodes.append(Episode(number: num, title: "الحلقة \(num)", pageURL: epURL))
        }
        episodes.sort { $0.number < $1.number }

        // Attach current-page servers to the episode that matches pageURL
        for i in episodes.indices {
            if episodes[i].pageURL == pageURL {
                episodes[i].servers = servers
            }
        }

        if episodes.isEmpty { return [] }

        // Check for multiple seasons
        let seasonLinks = (try? doc.select("a[href*='الموسم'], a[href*='season']").array()) ?? []
        if seasonLinks.count > 1 {
            var seasons: [Season] = []
            for (si, sl) in seasonLinks.enumerated() {
                let stitle = ((try? sl.text()) ?? "الموسم \(si+1)")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                seasons.append(Season(number: si + 1, title: stitle, episodes: []))
            }
            seasons[seasons.count - 1].episodes = episodes
            return seasons
        }

        return [Season(number: 1, title: "الموسم الأول", episodes: episodes)]
    }

    // =========================================================
    // MARK: - Regex / string helpers
    // =========================================================

    // loadIframe(this, 'URL')  →  URL
    private func extractLoadIframeURL(_ s: String) -> String? {
        regex(#"loadIframe\s*\([^,]+,\s*['"]([^'"]+)['"]\)"#, in: s)
    }

    // https://egibest.ws/watch/?url=ENCODED  →  ENCODED
    private func extractAfterURLParam(_ s: String) -> String {
        if let r = s.range(of: "?url=") {
            let enc = String(s[r.upperBound...])
            return enc.removingPercentEncoding ?? enc
        }
        return s
    }

    // Pull loadIframe URLs from raw JS text
    private func extractJSServers(js: String) -> [StreamServer] {
        var results: [StreamServer] = []
        guard let re = try? NSRegularExpression(
            pattern: #"loadIframe\s*\([^,]+,\s*['"]([^'"]+)['"]\)"#)
        else { return [] }
        let matches = re.matches(in: js, range: NSRange(js.startIndex..., in: js))
        for (i, m) in matches.enumerated() {
            guard let r = Range(m.range(at: 1), in: js) else { continue }
            let url = String(js[r])
            let encoded = extractAfterURLParam(url)
            results.append(StreamServer(name: "سيرفر \(i+1)", encodedPayload: encoded))
        }
        return results
    }

    private func detectType(url: String, title: String) -> MediaType {
        let s = (url + title).lowercased()
        if s.contains("anime") || s.contains("انمي") || s.contains("كرتون") { return .anime }
        if s.contains("series") || s.contains("مسلسل") || s.contains("حلقة") { return .series }
        return .movie
    }

    private func extractNumber(_ text: String) -> Int? {
        guard let s = regex(#"\d+"#, in: text) else { return nil }
        return Int(s)
    }

    // ─── Generic regex ────────────────────────────────────────────
    func regex(_ pattern: String, in text: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        guard let m = re.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let r = m.numberOfRanges > 1 ? m.range(at: 1) : m.range(at: 0)
        guard r.location != NSNotFound else { return nil }
        return ns.substring(with: r)
    }

    // ─── Base-64 decode ───────────────────────────────────────────
    func decodeBase64(_ s: String) -> String? {
        var padded = s.replacingOccurrences(of: "-", with: "+")
                      .replacingOccurrences(of: "_", with: "/")
        let rem = padded.count % 4
        if rem != 0 { padded += String(repeating: "=", count: 4 - rem) }
        guard let data = Data(base64Encoded: padded),
              let decoded = String(data: data, encoding: .utf8)
        else { return nil }
        return decoded
    }

    // ─── Small helper ─────────────────────────────────────────────
    private func firstNonEmpty(_ values: String?...) -> String? {
        values.first(where: { $0 != nil && !$0!.isEmpty }) ?? nil
    }
}
