//
//  StreamResolver.swift
//  ZCinema
//
//  Created by User on 2025-01-01.
//

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
                if best?.type == .mp4 {
                    break
                }
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
        if let decoded = await scraper.decodeBase64URL(server.encodedURL) {
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
        
        // Otherwise, fetch the page and try to extract iframe/video sources
        do {
            let (data, _) = try await session.data(from: url)
            let html = String(data: data, encoding: .utf8) ?? ""
            
            // Look for iframe source
            if let iframeSrc = extractIframeSource(from: html) {
                return ResolvedStream(directURL: iframeSrc, type: .iframe, quality: "SD", serverName: serverName)
            }
            
            // Look for video source (mp4/m3u8) inside the page
            if let videoURL = extractVideoSource(from: html) {
                let type: StreamType = videoURL.contains(".m3u8") ? .m3u8 : .mp4
                return ResolvedStream(directURL: videoURL, type: type, quality: "HD", serverName: serverName)
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func extractIframeSource(from html: String) -> String? {
        let pattern = #"<iframe[^>]+src=["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
        if let match = regex.firstMatch(in: html, options: [], range: nsRange),
           let range = Range(match.range(at: 1), in: html) {
            return String(html[range])
        }
        return nil
    }
    
    private func extractVideoSource(from html: String) -> String? {
        // Look for source tags
        let sourcePattern = #"<source[^>]+src=["']([^"']+\.(mp4|m3u8))["']"#
        if let regex = try? NSRegularExpression(pattern: sourcePattern, options: .caseInsensitive) {
            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: nsRange),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        
        // Look for video tag with src
        let videoPattern = #"<video[^>]+src=["']([^"']+\.(mp4|m3u8))["']"#
        if let regex = try? NSRegularExpression(pattern: videoPattern, options: .caseInsensitive) {
            let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)
            if let match = regex.firstMatch(in: html, options: [], range: nsRange),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Types
enum StreamType {
    case mp4
    case m3u8
    case iframe
}

struct ResolvedStream {
    let directURL: String
    let type: StreamType
    let quality: String
    let serverName: String
}

struct StreamServer {
    let name: String
    let encodedURL: String
}

enum ScraperError: Error {
    case noStreamFound
}
