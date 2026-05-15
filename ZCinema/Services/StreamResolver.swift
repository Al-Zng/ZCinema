import Foundation

// MARK: - StreamResolver
// Fires all servers concurrently, returns first valid mp4 or m3u8
actor StreamResolver {
    static let shared = StreamResolver()

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 18
        cfg.timeoutIntervalForResource = 30
        cfg.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Referer": "https://egibest.ws/"
        ]
        return URLSession(configuration: cfg)
    }()

    // ─── Public entry ─────────────────────────────────────────────
    func resolve(servers: [StreamServer]) async -> ResolvedStream? {
        guard !servers.isEmpty else { return nil }

        return await withTaskGroup(of: ResolvedStream?.self) { group in
            for server in servers {
                group.addTask { [self] in
                    return try? await self.resolveOne(server)
                }
            }

            var best: ResolvedStream? = nil
            for await result in group {
                guard let r = result else { continue }
                switch r.kind {
                case .mp4:
                    best = r          // perfect — stop immediately
                    group.cancelAll()
                    return best
                case .hls:
                    if best == nil || best?.kind == .iframe { best = r }
                case .iframe:
                    if best == nil { best = r }
                }
            }
            return best
        }
    }

    // ─── Resolve a single server ──────────────────────────────────
    private func resolveOne(_ server: StreamServer) async throws -> ResolvedStream {
        let scraper = Scraper.shared

        // 1) Try to decode base64 payload → direct URL
        let decoded = scraper.decodeBase64(server.encodedPayload) ?? server.encodedPayload

        // If decoded is already a direct media URL
        if let direct = directMediaURL(decoded) { return direct }

        // 2) Fetch the decoded/raw URL and scan HTML
        if let fetched = await fetchAndScan(decoded, serverName: server.name) { return fetched }

        // 3) Try egibest watch proxy
        let watchURL = "https://egibest.ws/watch/?url=\(server.encodedPayload)"
        if let fetched = await fetchAndScan(watchURL, serverName: server.name) { return fetched }

        throw ScraperError.noStream
    }

    // ─── Fetch page and scan for media URL ───────────────────────
    private func fetchAndScan(_ urlString: String, serverName: String) async -> ResolvedStream? {
        guard let url = URL(string: urlString) else { return nil }
        guard let (data, _) = try? await session.data(from: url),
              let html = String(data: data, encoding: .utf8)
                      ?? String(data: data, encoding: .isoLatin1)
        else { return nil }
        return extractFromHTML(html, pageURL: urlString)
    }

    // ─── Extract media URL from HTML ─────────────────────────────
    private func extractFromHTML(_ html: String, pageURL: String) -> ResolvedStream? {
        let scraper = Scraper.shared

        // --- mp4 patterns (highest priority) ---

        // <source src="...mp4">
        if let u = scraper.regex(#"<source[^>]+src=["']([^"']+\.mp4[^"']*)"#, in: html) {
            return .init(url: abs(u, base: pageURL), kind: .mp4, quality: quality(u))
        }
        // jwplayer / videojs file: "..."
        if let u = scraper.regex(#"(?:file|src)\s*[=:]\s*["']([^"']+\.mp4[^"']*)"#, in: html) {
            return .init(url: abs(u, base: pageURL), kind: .mp4, quality: quality(u))
        }
        // Generic https …mp4
        if let u = scraper.regex(#"["'](https?://[^"'\s]+\.mp4[^"'\s]*)"#, in: html) {
            if !u.contains("placeholder") && !u.contains("default") {
                return .init(url: u, kind: .mp4, quality: quality(u))
            }
        }
        // DoodStream pass_md5 → we store the link, app fetches it at play time
        if pageURL.contains("doodstream") || html.contains("pass_md5") {
            if let token = scraper.regex(#"/pass_md5/([^'"\s/]+)"#, in: html) {
                let dood = "https://doodstream.com/pass_md5/\(token)"
                return .init(url: dood, kind: .mp4, quality: "HD")
            }
        }
        // Mixdrop wurl
        if html.contains("mixdrop") || pageURL.contains("mixdrop") {
            if let u = scraper.regex(#"(?:wurl|MDCore\.wurl)\s*=\s*["']([^"']+)"#, in: html) {
                let full = u.hasPrefix("//") ? "https:\(u)" : u
                return .init(url: full, kind: .mp4, quality: "HD")
            }
        }
        // Streamtape robotlink
        if html.contains("streamtape") || pageURL.contains("streamtape") {
            if let u = scraper.regex(#"robotlink[^'\"]*['\"]//([^'\"]+)"#, in: html) {
                return .init(url: "https://\(u)", kind: .mp4, quality: "HD")
            }
            if let u = scraper.regex(#"getElementById\([^)]+\)\.innerHTML\s*=\s*['"]\s*([^'"]+)"#, in: html) {
                let full = u.hasPrefix("//") ? "https:\(u)" : u
                return .init(url: full, kind: .mp4, quality: "HD")
            }
        }
        // Cybervynx / lulustream — try generic https mp4 again after known-host checks
        if let u = scraper.regex(#"["'](https?://[^"'\s]+\.mp4[^"'\s]*)"#, in: html) {
            return .init(url: u, kind: .mp4, quality: quality(u))
        }

        // --- HLS / m3u8 patterns ---
        if let u = scraper.regex(#"["']([^"']+\.m3u8[^"']*)"#, in: html) {
            return .init(url: abs(u, base: pageURL), kind: .hls, quality: "HD")
        }
        if let u = scraper.regex(#"(?:hlsSrc|hls_src|source)\s*[=:]\s*["']([^"']+)"#, in: html) {
            return .init(url: abs(u, base: pageURL), kind: .hls, quality: "HD")
        }

        // --- iframe fallback ---
        if let u = scraper.regex(#"<iframe[^>]+src=["']([^"']+)"#, in: html) {
            if u != "about:blank" && !u.isEmpty {
                return .init(url: abs(u, base: pageURL), kind: .iframe, quality: "—")
            }
        }

        return nil
    }

    // ─── Check if a raw string is already a media URL ────────────
    private func directMediaURL(_ s: String) -> ResolvedStream? {
        guard s.hasPrefix("http") else { return nil }
        if s.contains(".mp4")  { return .init(url: s, kind: .mp4,  quality: quality(s)) }
        if s.contains(".m3u8") { return .init(url: s, kind: .hls,  quality: "HD") }
        return nil
    }

    // ─── Helpers ─────────────────────────────────────────────────
    private func abs(_ path: String, base: String) -> String {
        if path.hasPrefix("http") { return path }
        if path.hasPrefix("//")   { return "https:\(path)" }
        if path.hasPrefix("/") {
            if let host = URL(string: base)?.host {
                return "https://\(host)\(path)"
            }
        }
        return path
    }

    private func quality(_ url: String) -> String {
        if url.contains("1080") { return "1080p" }
        if url.contains("720")  { return "720p"  }
        if url.contains("480")  { return "480p"  }
        if url.contains("360")  { return "360p"  }
        return "HD"
    }
}
