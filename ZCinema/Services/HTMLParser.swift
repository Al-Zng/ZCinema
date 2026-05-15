import Foundation

class HTMLParser {
    func parseHomePage(html: String, baseURL: String) async throws -> [ScraperService.HomeSection] {
        var sections: [ScraperService.HomeSection] = []
        
        // Parse based on observed structure from provided HTML files
        // Look for divs with class "pageContent"
        let pageContentPattern = #"<div class="pageContent">(.*?)<div class="postSlider">"#
        
        let regex = try NSRegularExpression(pattern: pageContentPattern, options: [.dotMatchesLineSeparators])
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        
        // Also parse categories using class "mainTitle"
        let titlePattern = #"<h2 class="mainTitle\s*">(.*?)<a class="fLeft more".*?>(.*?)</a>"#
        let titleRegex = try NSRegularExpression(pattern: titlePattern, options: [])
        let titleMatches = titleRegex.matches(in: html, options: [], range: nsRange)
        
        // Parse slide items (postBlock)
        let itemPattern = #"<a class="postBlock" href="([^"]+)"[^>]*title="([^"]+)">\s*<div class="postBlockImg">\s*<img[^>]+data-img="([^"]+)"[^>]*>.*?<h3 class="title">(.*?)</h3>"#
        let itemRegex = try NSRegularExpression(pattern: itemPattern, options: [.dotMatchesLineSeparators])
        let itemMatches = itemRegex.matches(in: html, options: [], range: nsRange)
        
        // Extract sections from the page
        // Based on the HTML structure, we need to find each section by its title
        let sectionTitles = [
            "جديد ايجى بست",
            "افلام",
            "مسلسلات",
            "انمى",
            "افلام 2025",
            "أفضل مسلسلات هذا الشهر"
        ]
        
        // For now, build mock sections from the first few items
        var itemsBySection: [String: [ContentItem]] = [:]
        
        for match in itemMatches.prefix(30) {
            guard match.numberOfRanges >= 5 else { continue }
            
            let urlRange = Range(match.range(at: 1), in: html)!
            let titleRange = Range(match.range(at: 2), in: html)!
            let imgRange = Range(match.range(at: 3), in: html)!
            let nameRange = Range(match.range(at: 4), in: html)!
            
            let url = String(html[urlRange])
            let title = String(html[titleRange])
            let imgUrl = String(html[imgRange])
            let displayName = String(html[nameRange])
            
            let type: ContentItem.ContentType = url.contains("مسلسل") ? .series : (url.contains("انمي") ? .anime : .movie)
            
            let item = ContentItem(
                title: displayName,
                url: url,
                imageUrl: imgUrl,
                type: type,
                rating: "8.1",
                year: nil,
                description: nil,
                genres: nil,
                seasons: nil
            )
            
            let sectionKey = determineSectionForItem(html: html, matchRange: match.range)
            itemsBySection[sectionKey, default: []].append(item)
        }
        
        for title in sectionTitles {
            if let items = itemsBySection[title], !items.isEmpty {
                sections.append(ScraperService.HomeSection(title: title, items: Array(items.prefix(10)), seeAllUrl: nil))
            }
        }
        
        if sections.isEmpty {
            // Fallback: create one section with all items
            let allItems = itemMatches.prefix(10).compactMap { match -> ContentItem? in
                guard match.numberOfRanges >= 5 else { return nil }
                let urlRange = Range(match.range(at: 1), in: html)!
                let titleRange = Range(match.range(at: 2), in: html)!
                let imgRange = Range(match.range(at: 3), in: html)!
                let nameRange = Range(match.range(at: 4), in: html)!
                
                return ContentItem(
                    title: String(html[nameRange]),
                    url: String(html[urlRange]),
                    imageUrl: String(html[imgRange]),
                    type: .movie,
                    rating: "8.1",
                    year: nil,
                    description: nil,
                    genres: nil,
                    seasons: nil
                )
            }
            sections.append(ScraperService.HomeSection(title: "أحدث الإضافات", items: allItems, seeAllUrl: nil))
        }
        
        return sections
    }
    
    private func determineSectionForItem(html: String, matchRange: NSRange) -> String {
        // Try to find which section container this item belongs to
        // Simplified: return based on URL context
        return "جديد ايجى بست"
    }
    
    func parseContentDetail(html: String, baseURL: String) async throws -> ContentItem? {
        // Extract title
        let titlePattern = #"<h1[^>]*>(.*?)</h1>"#
        let title = extractFirstMatch(pattern: titlePattern, from: html)?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract image
        let imgPattern = #"<div class="postImg">.*?<img[^>]+data-src="([^"]+)"[^>]*>"#
        let imageUrl = extractFirstMatch(pattern: imgPattern, from: html)
        
        // Extract description
        let descPattern = #"<p class="description">(.*?)</p>"#
        let description = extractFirstMatch(pattern: descPattern, from: html)?.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Extract rating
        let ratingPattern = #"rating"><i>([\d\.]+)</i>"#
        let rating = extractFirstMatch(pattern: ratingPattern, from: html)
        
        // Extract year
        let yearPattern = #"سنة الإنتاج<\/td>\s*<td>.*?(\d{4})"#
        let year = extractFirstMatch(pattern: yearPattern, from: html)
        
        // Extract genres
        let genrePattern = #"النوع<\/td>\s*<td>(.*?)</td>"#
        let genreHtml = extractFirstMatch(pattern: genrePattern, from: html)
        let genres = genreHtml?.components(separatedBy: "</a>").compactMap { part -> String? in
            let clean = part.replacingOccurrences(of: "<a[^>]*>", with: "", options: .regularExpression)
            return clean.isEmpty ? nil : clean
        }
        
        // Determine type
        let type: ContentItem.ContentType = html.contains("مسلسلات") ? .series : (html.contains("انمى") ? .anime : .movie)
        
        // Extract seasons and episodes for series
        var seasons: [Season]? = nil
        if type == .series {
            seasons = parseSeasons(from: html, baseURL: baseURL)
        }
        
        guard let finalTitle = title, let finalImageUrl = imageUrl else {
            return nil
        }
        
        return ContentItem(
            title: finalTitle,
            url: "",
            imageUrl: finalImageUrl,
            type: type,
            rating: rating,
            year: year,
            description: description,
            genres: genres,
            seasons: seasons
        )
    }
    
    private func parseSeasons(from html: String, baseURL: String) -> [Season]? {
        var seasons: [Season] = []
        
        // Look for season selector or episode list
        let episodePattern = #"<a\s+(?:class="[^"]*"?\s+)?href="([^"]+)"[^>]*>\s*الحلقة\s*<em>(\d+)</em>"#
        let regex = try? NSRegularExpression(pattern: episodePattern, options: [])
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex?.matches(in: html, options: [], range: nsRange) ?? []
        
        var episodes: [Episode] = []
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let urlRange = Range(match.range(at: 1), in: html)!
            let numRange = Range(match.range(at: 2), in: html)!
            let url = String(html[urlRange])
            let episodeNum = Int(String(html[numRange])) ?? 0
            episodes.append(Episode(episodeNumber: episodeNum, title: "الحلقة \(episodeNum)", url: url, thumbnailUrl: nil))
        }
        
        if !episodes.isEmpty {
            episodes.sort { $0.episodeNumber < $1.episodeNumber }
            seasons.append(Season(seasonNumber: 1, episodes: episodes))
        }
        
        return seasons.isEmpty ? nil : seasons
    }
    
    func parseVideoServers(html: String, baseURL: String) async throws -> [VideoServer] {
        var servers: [VideoServer] = []
        
        // Look for server list items with onclick that contains watch url
        let serverPattern = #"<li[^>]*onclick="loadIframe\(this,\s*'([^']+)'\)"[^>]*>.*?<i[^>]*></i>\s*([^<]+)"#
        let regex = try NSRegularExpression(pattern: serverPattern, options: [])
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: nsRange)
        
        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }
            let urlRange = Range(match.range(at: 1), in: html)!
            let nameRange = Range(match.range(at: 2), in: html)!
            
            var url = String(html[urlRange])
            let name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Resolve relative URLs
            if url.hasPrefix("/") {
                url = baseURL + url
            }
            
            let server = VideoServer(name: name, embedUrl: url, downloadUrl: nil, quality: nil)
            servers.append(server)
        }
        
        // Also parse download links from the download section
        if let downloadSection = extractDownloadLinks(html: html) {
            servers.append(contentsOf: downloadSection)
        }
        
        return servers
    }
    
    private func extractDownloadLinks(html: String) -> [VideoServer]? {
        // Look for download buttons with data-id mapping to encoded links in JavaScript
        let downloadDataPattern = #"let downloadLinks = (\{.*?\})"#
        if let dataJson = extractFirstMatch(pattern: downloadDataPattern, from: html),
           let jsonData = dataJson.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] {
            
            var servers: [VideoServer] = []
            for (id, encodedUrl) in dict {
                if let decodedData = Data(base64Encoded: encodedUrl),
                   let decodedUrl = String(data: decodedData, encoding: .utf8) {
                    servers.append(VideoServer(name: "تحميل \(id)", embedUrl: "", downloadUrl: decodedUrl, quality: nil))
                }
            }
            return servers
        }
        return nil
    }
    
    private func extractFirstMatch(pattern: String, from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { return nil }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: nsRange) else { return nil }
        guard match.numberOfRanges > 1 else { return nil }
        let range = Range(match.range(at: 1), in: html)!
        return String(html[range])
    }
}