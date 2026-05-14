import Foundation
import SwiftSoup

// MARK: - EgyBest Scraper
actor EgyBestScraper {
    static let shared = EgyBestScraper()
    private let baseURL = "https://egibest.ws"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "ar,en;q=0.9",
            "Referer": "https://egibest.ws/"
        ]
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Fetch HTML
    func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw ScraperError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ScraperError.httpError
        }
        guard let html = String(data: data, encoding: .utf8) ??
                         String(data: data, encoding: .isoLatin1) else {
            throw ScraperError.decodingError
        }
        return html
    }
    
    // MARK: - Parse Home Sections
    func parseHomeSections(html: String) throws -> [HomeSection] {
        let doc = try SwiftSoup.parse(html)
        var sections: [HomeSection] = []
        
        let pageContents = try doc.select(".pageContent")
        
        for pageContent in pageContents.array() {
            guard let titleEl = try? pageContent.select(".mainTitle").first() else { continue }
            let rawTitle = (try? titleEl.ownText()) ?? ""
            let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
            
            let moreURL = (try? pageContent.select(".more").attr("href")) ?? ""
            
            var items: [MediaItem] = []
            let postBlocks = try pageContent.select(".postBlock")
            
            for block in postBlocks.array() {
                if let item = try? parsePostBlock(block) {
                    if !items.contains(where: { $0.url == item.url }) {
                        items.append(item)
                    }
                }
            }
            
            if !items.isEmpty {
                if !sections.contains(where: { $0.title == title }) {
                    sections.append(HomeSection(title: title, items: items, moreURL: moreURL))
                }
            }
        }
        
        return sections
    }
    
    // MARK: - Parse Post Block (Card)
    func parsePostBlock(_ element: Element) throws -> MediaItem {
        let href = (try? element.attr("href")) ?? ""
        let title = ((try? element.attr("title")) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Image
        let imgEl = try? element.select("img").first()
        let imgSrc = (try? imgEl?.attr("data-img")) ??
                     (try? imgEl?.attr("data-src")) ??
                     (try? imgEl?.attr("src")) ?? ""
        
        // Rating
        let ratingEl = try? element.select(".rating i").first()
        let rating = (try? ratingEl?.text()) ?? "8.1"
        
        // Determine type from URL/title
        let type = determineMediaType(from: href, title: title)
        
        let fullURL = href.hasPrefix("http") ? href : "\(baseURL)\(href)"
        
        return MediaItem(
            title: title,
            imageURL: imgSrc,
            rating: rating,
            url: fullURL,
            type: type
        )
    }
    
    // MARK: - Fetch Category/Section List
    func fetchMediaList(url: String, page: Int = 1) async throws -> [MediaItem] {
        let pageURL = page > 1 ? "\(url)page/\(page)/" : url
        let html = try await fetchHTML(from: pageURL)
        return try parseMediaList(html: html)
    }
    
    func parseMediaList(html: String) throws -> [MediaItem] {
        let doc = try SwiftSoup.parse(html)
        var items: [MediaItem] = []
        let blocks = try doc.select(".postBlock, .postBlockCol")
        for block in blocks.array() {
            if let item = try? parsePostBlock(block) {
                items.append(item)
            }
        }
        return items
    }
    
    // MARK: - Fetch Media Detail
    func fetchMediaDetail(url: String) async throws -> MediaItem {
        let html = try await fetchHTML(from: url)
        return try parseMediaDetail(html: html, url: url)
    }
    
    func parseMediaDetail(html: String, url: String) throws -> MediaItem {
        let doc = try SwiftSoup.parse(html)
        
        // Title
        let titleEl = try? doc.select(".postTitle h1").first()
        let title = ((try? titleEl?.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Image
        let imgEl = try? doc.select(".postImg img").first()
        let imageURL = (try? imgEl?.attr("data-src")) ??
                       (try? imgEl?.attr("src")) ?? ""
        
        // Description
        let descEl = try? doc.select("p.description").first()
        let description = ((try? descEl?.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Meta info from postTable
        var year = ""
        var category = ""
        var language = ""
        var quality = ""
        var country = ""
        var genres: [String] = []
        
        let rows = try doc.select(".postTable tr")
        for row in rows.array() {
            let cells = try row.select("td")
            guard cells.size() >= 2 else { continue }
            let label = (try? cells.get(0).text()) ?? ""
            let value = (try? cells.get(1).text()) ?? ""
            
            switch label {
            case _ where label.contains("سنة"):
                year = value
            case _ where label.contains("القسم"):
                category = value
            case _ where label.contains("النوع"):
                let genreLinks = try cells.get(1).select("a")
                genres = genreLinks.array().compactMap { try? $0.text() }
            case _ where label.contains("اللغة"):
                language = value
            case _ where label.contains("الجودة"):
                quality = value
            case _ where label.contains("الدولة"):
                country = value
            default:
                break
            }
        }
        
        // Servers
        let servers = try parseServers(doc: doc)
        
        // Episodes/Seasons
        let (seasons, episodes) = try parseEpisodesAndSeasons(doc: doc)
        
        // Type
        let type = determineMediaType(from: url, title: title)
        
        // Rating
        let ratingEl = try? doc.select(".postRating").first()
        let rating = (try? ratingEl?.text()) ?? "67%"
        
        var item = MediaItem(
            title: title,
            imageURL: imageURL,
            rating: rating,
            url: url,
            year: year,
            category: category,
            genre: genres,
            language: language,
            quality: quality,
            country: country,
            description: description,
            type: type,
            seasons: seasons
        )
        
        // If no seasons but has servers (movie or single episode)
        if seasons.isEmpty && !servers.isEmpty {
            let ep = Episode(number: 1, title: title, url: url, servers: servers)
            let season = Season(number: 1, title: "المحتوى", url: url, episodes: [ep])
            item.seasons = [season]
        } else if !seasons.isEmpty && !episodes.isEmpty {
            // Attach servers to current episode
            if var firstSeason = item.seasons.first,
               !firstSeason.episodes.isEmpty {
                var ep = firstSeason.episodes[0]
                ep.servers = servers
                firstSeason.episodes[0] = ep
                item.seasons[0] = firstSeason
            }
        }
        
        return item
    }
    
    // MARK: - Parse Servers
    func parseServers(doc: Document) throws -> [StreamServer] {
        var servers: [StreamServer] = []
        let serverItems = try doc.select("#watch-servers-list li")
        
        for (index, item) in serverItems.array().enumerated() {
            let onclick = (try? item.attr("onclick")) ?? ""
            let name = ((try? item.text()) ?? "Server \(index + 1)")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract URL from onclick: loadIframe(this, 'URL')
            if let encodedURL = extractURLFromOnclick(onclick) {
                // Extract encoded part after ?url=
                let encoded = extractEncodedURL(from: encodedURL)
                servers.append(StreamServer(
                    name: name.isEmpty ? "سيرفر \(index + 1)" : name,
                    encodedURL: encoded,
                    quality: "HD"
                ))
            }
        }
        
        // Also parse download links
        let downloadLinks = try doc.select("[data-id]")
        // The JS variable downloadLinks contains encoded URLs
        // We extract them from the script tag
        let scripts = try doc.select("script")
        for script in scripts.array() {
            let content = (try? script.html()) ?? ""
            if content.contains("downloadLinks") {
                let extracted = extractDownloadLinks(from: content)
                for (idx, link) in extracted.enumerated() {
                    if idx < servers.count {
                        servers[idx].encodedURL = link.value
                    }
                }
            }
        }
        
        return servers
    }
    
    // MARK: - Parse Episodes and Seasons
    func parseEpisodesAndSeasons(doc: Document) throws -> ([Season], [Episode]) {
        var seasons: [Season] = []
        var allEpisodes: [Episode] = []
        
        // Season buttons
        let seasonLinks = try doc.select(".pageContent a[href*='season'], .pageContent a[href*='موسم']")
        
        // Episode links in .all-episodes
        let episodeLinks = try doc.select(".all-episodes m a, .all-episodes a")
        
        var episodes: [Episode] = []
        for (idx, link) in episodeLinks.array().enumerated() {
            let href = (try? link.attr("href")) ?? ""
            let text = ((try? link.text()) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let epNum = extractEpisodeNumber(from: text) ?? (idx + 1)
            let fullURL = href.hasPrefix("http") ? href : "\(baseURL)\(href)"
            
            let ep = Episode(number: epNum, title: "الحلقة \(epNum)", url: fullURL)
            episodes.append(ep)
            allEpisodes.append(ep)
        }
        
        if !episodes.isEmpty {
            let season = Season(number: 1, title: "الموسم الأول", url: "", episodes: episodes.reversed())
            seasons.append(season)
        }
        
        return (seasons, allEpisodes)
    }
    
    // MARK: - Resolve Stream URL
    func resolveStreamURL(server: StreamServer) async throws -> ResolvedStream {
        let watchURL = server.watchURL
        
        // Try to get the actual watch page
        guard let url = URL(string: watchURL) else {
            throw ScraperError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("https://egibest.ws/", forHTTPHeaderField: "Referer")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // Check for redirect
                if let finalURL = httpResponse.url?.absoluteString {
                    // Try to resolve iframe source
                    if let html = String(data: data, encoding: .utf8) {
                        if let resolved = try? extractDirectURL(from: html, baseURL: finalURL) {
                            return resolved
                        }
                    }
                }
            }
        } catch { }
        
        // Fallback: decode base64 and try
        if let decoded = decodeBase64URL(server.encodedURL) {
            return ResolvedStream(
                directURL: decoded,
                type: decoded.contains(".m3u8") ? .m3u8 : decoded.contains(".mp4") ? .mp4 : .iframe,
                quality: server.quality,
                serverName: server.name
            )
        }
        
        return ResolvedStream(
            directURL: watchURL,
            type: .iframe,
            quality: server.quality,
            serverName: server.name
        )
    }
    
    // MARK: - Search
    func search(query: String) async throws -> [MediaItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let searchURL = "\(baseURL)/?s=\(encodedQuery)"
        let html = try await fetchHTML(from: searchURL)
        return try parseMediaList(html: html)
    }
    
    // MARK: - Helper: Extract Direct URL from HTML
    private func extractDirectURL(from html: String, baseURL: String) throws -> ResolvedStream? {
        let doc = try SwiftSoup.parse(html)
        
        // Look for video sources
        let videoSources = try doc.select("video source, source[type*='video']")
        for src in videoSources.array() {
            let srcURL = (try? src.attr("src")) ?? ""
            if !srcURL.isEmpty {
                let type: ResolvedStream.StreamType = srcURL.contains(".m3u8") ? .m3u8 : .mp4
                return ResolvedStream(directURL: srcURL, type: type, quality: "HD", serverName: "")
            }
        }
        
        // Look for jwplayer setup
        if html.contains("jwplayer") || html.contains("file:") {
            if let mp4URL = extractRegex(pattern: #"file\s*:\s*["']([^"']+\.mp4[^"']*)"#, from: html) {
                return ResolvedStream(directURL: mp4URL, type: .mp4, quality: "HD", serverName: "")
            }
            if let m3u8URL = extractRegex(pattern: #"file\s*:\s*["']([^"']+\.m3u8[^"']*)"#, from: html) {
                return ResolvedStream(directURL: m3u8URL, type: .m3u8, quality: "HD", serverName: "")
            }
        }
        
        // Look for sources array
        if let mp4URL = extractRegex(pattern: #"["']([^"']+\.mp4[^"']*)"#, from: html) {
            return ResolvedStream(directURL: mp4URL, type: .mp4, quality: "HD", serverName: "")
        }
        
        if let m3u8URL = extractRegex(pattern: #"["']([^"']+\.m3u8[^"']*)"#, from: html) {
            return ResolvedStream(directURL: m3u8URL, type: .m3u8, quality: "HD", serverName: "")
        }
        
        // iframe src
        let iframes = try doc.select("iframe[src]")
        for iframe in iframes.array() {
            let src = (try? iframe.attr("src")) ?? ""
            if src.contains("embed") || src.contains("player") || src.contains("watch") {
                return ResolvedStream(directURL: src, type: .iframe, quality: "HD", serverName: "")
            }
        }
        
        return nil
    }
    
    // MARK: - Helper Functions
    private func extractURLFromOnclick(_ onclick: String) -> String? {
        let pattern = #"loadIframe\s*\(\s*this\s*,\s*['"]([^'"]+)['"]\s*\)"#
        return extractRegex(pattern: pattern, from: onclick)
    }
    
    private func extractEncodedURL(from watchURL: String) -> String {
        if let range = watchURL.range(of: "?url=") {
            let encoded = String(watchURL[range.upperBound...])
            return encoded.removingPercentEncoding ?? encoded
        }
        return watchURL
    }
    
    private func extractDownloadLinks(from script: String) -> [String: String] {
        var links: [String: String] = [:]
        // Match: "1":"encodedURL", "2":"encodedURL"
        let pattern = #""(\d+)"\s*:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return links }
        let matches = regex.matches(in: script, range: NSRange(script.startIndex..., in: script))
        for match in matches {
            if let keyRange = Range(match.range(at: 1), in: script),
               let valRange = Range(match.range(at: 2), in: script) {
                let key = String(script[keyRange])
                let val = String(script[valRange])
                links[key] = val
            }
        }
        return links
    }
    
    func decodeBase64URL(_ encoded: String) -> String? {
        // Remove percent encoding first
        let cleaned = encoded.removingPercentEncoding ?? encoded
        // Pad base64 if needed
        var padded = cleaned
        let remainder = padded.count % 4
        if remainder != 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: padded),
              let decoded = String(data: data, encoding: .utf8) else {
            return nil
        }
        return decoded
    }
    
    private func extractEpisodeNumber(from text: String) -> Int? {
        let pattern = #"\d+"#
        if let match = extractRegex(pattern: pattern, from: text) {
            return Int(match)
        }
        return nil
    }
    
    func extractRegex(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range(at: 0)
        guard let swiftRange = Range(captureRange, in: text) else { return nil }
        return String(text[swiftRange])
    }
    
    func determineMediaType(from url: String, title: String) -> MediaType {
        let lower = url.lowercased() + title.lowercased()
        if lower.contains("anime") || lower.contains("انمي") || lower.contains("كرتون") {
            return .anime
        } else if lower.contains("series") || lower.contains("مسلسل") || lower.contains("حلقة") || lower.contains("الموسم") {
            return .series
        }
        return .movie
    }
    
    // MARK: - Fetch with specific category
    func fetchMovies(page: Int = 1) async throws -> [MediaItem] {
        return try await fetchMediaList(url: "\(baseURL)/movies/", page: page)
    }
    
    func fetchSeries(page: Int = 1) async throws -> [MediaItem] {
        return try await fetchMediaList(url: "\(baseURL)/series/", page: page)
    }
    
    func fetchAnime(page: Int = 1) async throws -> [MediaItem] {
        return try await fetchMediaList(url: "\(baseURL)/category/anime/", page: page)
    }
    
    func fetchHome() async throws -> [HomeSection] {
        let html = try await fetchHTML(from: baseURL)
        return try parseHomeSections(html: html)
    }
}

// MARK: - Scraper Errors
enum ScraperError: LocalizedError {
    case invalidURL
    case httpError
    case decodingError
    case parsingError
    case noStreamFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "رابط غير صحيح"
        case .httpError: return "خطأ في الاتصال بالسيرفر"
        case .decodingError: return "خطأ في قراءة البيانات"
        case .parsingError: return "خطأ في تحليل البيانات"
        case .noStreamFound: return "لم يتم العثور على رابط البث"
        }
    }
}
