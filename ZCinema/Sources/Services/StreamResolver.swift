import Foundation

// MARK: - Stream Resolver
// Automatically scans all servers and extracts direct mp4/m3u8 links
actor StreamResolver {
    static let shared = StreamResolver()
    
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "*/*",
            "Accept-Language": "ar,en;q=0.9"
        ]
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Main Entry: Resolve best stream from all servers
    func resolveBestStream(from servers: [StreamServer]) async -> ResolvedStream? {
        // Try all servers concurrently and return first valid stream
        await withTaskGroup(of: ResolvedStream?.self) { group in
            for server in servers {
                group.addTask {
                    return try? await self.resolveServer(server)
                }
            }
            
            var best: ResolvedStream? = nil
            for await result in group {
                guard let stream = result else { continue }
                // Prefer mp4 > m3u8 > iframe
                switch stream.type {
                case .mp4:
                    if best == nil || best?.type == .m3u8 || best?.type == .iframe {
                        best = stream
                    }
                case .m3u8:
                    if best == nil || best?.type == .iframe {
                        best = stream
                    }
                case .iframe:
                    if best == nil {
                        best = stream
                    }
                }
                // If we got mp4, stop waiting
                if best?.type == .mp4 { break }
            }
            return best
        }
    }
    
    // MARK: - Resolve All Servers (returns array sorted by quality)
    func resolveAllStreams(from servers: [StreamServer]) async -> [ResolvedStream] {
        var results: [ResolvedStream] = []
        
        await withTaskGroup(of: ResolvedStream?.self) { group in
            for server in servers {
                group.addTask {
                    return try? await self.resolveServer(server)
                }
            }
            for await result in group {
                if let stream = result {
                    results.append(stream)
                }
            }
        }
        
        // Sort: mp4 first, then m3u8, then iframe
        return results.sorted { a, b in
            let rank: (ResolvedStream) -> Int = { s in
                switch s.type {
                case .mp4: return 0
                case .m3u8: return 1
                case .iframe: return 2
                }
            }
            return rank(a) < rank(b)
        }
    }
    
    // MARK: - Resolve Single Server
    func resolveServer(_ server: StreamServer) async throws -> ResolvedStream {
        // Step 1: Decode base64 encoded URL
        let scraper = EgyBestScraper.shared
        
        // The encoded URL from the site is base64
        if let decoded = scraper.decodeBase64URL(server.encodedURL) {
            // Step 2: Try to extract stream from the decoded URL
            if let stream = await extractStreamFromURL(decoded, serverName: server.name) {
                return stream
            }
        }
        
        // Step 3: Try via egibest watch endpoint
        let watchURL = "https://egibest.ws/watch/?url=\(server.encodedURL)"
        if let stream = await extractStreamFromURL(watchURL, serverName: server.name) {
            return stream
        }
        
        throw ScraperError.noStreamFound
    }
    
    // MARK: - Extract Stream from URL
    private func extractStreamFromURL(_ urlString: String, serverName: String) async -> ResolvedStream? {
        guard let url = URL(string: urlString) else { return nil }
        
        // Direct link check
        if urlString.contains(".mp4") {
            return ResolvedStream(directURL: urlString, type: .mp4, quality: "HD", serverName: serverName)
        }
        if urlString.contains(".m3u8") {
            return ResolvedStream(directURL: urlString, type: .m3u8, quality: "HD", serverName: serverName)
        }
        
        // Fetch the page
        var request = URLRequest(url: url)
        request.setValue("https://egibest.ws/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        guard let (data, response) = try? await session.data(for: request),
              let html = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Check final URL after redirects
        let finalURL = (response as? HTTPURLResponse)?.url?.absoluteString ?? urlString
        
        // Try all extraction methods
        return extractFromHTML(html, finalURL: finalURL, serverName: serverName)
    }
    
    // MARK: - Extract from HTML Content
    private func extractFromHTML(_ html: String, finalURL: String, serverName: String) -> ResolvedStream? {
        // 1. Direct mp4 in source tags
        if let url = matchRegex(#"<source[^>]+src=["']([^"']+\.mp4[^"']*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .mp4, quality: extractQuality(from: url), serverName: serverName)
        }
        
        // 2. Direct m3u8 in source tags
        if let url = matchRegex(#"<source[^>]+src=["']([^"']+\.m3u8[^"']*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .m3u8, quality: "HD", serverName: serverName)
        }
        
        // 3. JWPlayer file config
        if let url = matchRegex(#"file\s*:\s*["']([^"']+\.mp4[^"']*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .mp4, quality: extractQuality(from: url), serverName: serverName)
        }
        if let url = matchRegex(#"file\s*:\s*["']([^"']+\.m3u8[^"']*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .m3u8, quality: "HD", serverName: serverName)
        }
        
        // 4. sources array in JS
        if let url = matchRegex(#""file"\s*:\s*"([^"]+\.mp4[^"]*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .mp4, quality: extractQuality(from: url), serverName: serverName)
        }
        if let url = matchRegex(#""file"\s*:\s*"([^"]+\.m3u8[^"]*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .m3u8, quality: "HD", serverName: serverName)
        }
        
        // 5. DoodStream pattern
        if finalURL.contains("doodstream") || html.contains("doodstream") {
            if let token = matchRegex(#"pass_md5/([^/'"]+)"#, in: html) {
                let doodURL = "https://doodstream.com/pass_md5/\(token)"
                return ResolvedStream(directURL: doodURL, type: .mp4, quality: "HD", serverName: serverName)
            }
        }
        
        // 6. Mixdrop pattern
        if finalURL.contains("mixdrop") || html.contains("mixdrop") {
            if let url = matchRegex(#"wurl\s*=\s*["']([^"']+)"#, in: html) {
                let full = url.hasPrefix("//") ? "https:\(url)" : url
                return ResolvedStream(directURL: full, type: .mp4, quality: "HD", serverName: serverName)
            }
            if let url = matchRegex(#"MDCore\.wurl\s*=\s*["']([^"']+)"#, in: html) {
                let full = url.hasPrefix("//") ? "https:\(url)" : url
                return ResolvedStream(directURL: full, type: .mp4, quality: "HD", serverName: serverName)
            }
        }
        
        // 7. Streamtape pattern
        if finalURL.contains("streamtape") || html.contains("streamtape") {
            if let url = matchRegex(#"document\.getElementById\([^)]+\)\.innerHTML\s*=\s*["']([^"']+)"#, in: html) {
                return ResolvedStream(directURL: "https://streamtape.com\(url)", type: .mp4, quality: "HD", serverName: serverName)
            }
            // Alternative streamtape extraction
            if let url = matchRegex(#"robotlink\)\.innerHTML = '//([^']+)'"#, in: html) {
                return ResolvedStream(directURL: "https://\(url)", type: .mp4, quality: "HD", serverName: serverName)
            }
        }
        
        // 8. Lulustream / generic stream
        if let url = matchRegex(#"["'](https?://[^"']+\.mp4[^"']*)"#, in: html) {
            if !url.contains("placeholder") && !url.contains("default") {
                return ResolvedStream(directURL: url, type: .mp4, quality: extractQuality(from: url), serverName: serverName)
            }
        }
        if let url = matchRegex(#"["'](https?://[^"']+\.m3u8[^"']*)"#, in: html) {
            return ResolvedStream(directURL: url, type: .m3u8, quality: "HD", serverName: serverName)
        }
        
        // 9. HLS source
        if let url = matchRegex(#"hls[Ss]rc\s*[=:]\s*["']([^"']+)"#, in: html) {
            return ResolvedStream(directURL: url, type: .m3u8, quality: "HD", serverName: serverName)
        }
        
        // 10. Iframe embed as fallback
        if let url = matchRegex(#"<iframe[^>]+src=["']([^"']+)"#, in: html) {
            if !url.isEmpty && url != "about:blank" {
                return ResolvedStream(directURL: url, type: .iframe, quality: "HD", serverName: serverName)
            }
        }
        
        return nil
    }
    
    // MARK: - Quality Extraction
    private func extractQuality(from url: String) -> String {
        if url.contains("1080") { return "1080p" }
        if url.contains("720") { return "720p" }
        if url.contains("480") { return "480p" }
        if url.contains("360") { return "360p" }
        return "HD"
    }
    
    // MARK: - Regex Helper
    private func matchRegex(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        let captureRange = match.numberOfRanges > 1 ? match.range(at: 1) : match.range(at: 0)
        guard let swiftRange = Range(captureRange, in: text) else { return nil }
        return String(text[swiftRange])
    }
}
