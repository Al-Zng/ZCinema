import Foundation

struct CybervynxParser: VideoParser {
    static func extractVideoUrl(from pageUrl: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: pageUrl) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            // Cybervynx and lulustream typically use standard video elements
            let patterns = [
                #"<video[^>]+src="([^"]+\.(?:mp4|m3u8)[^"]*)"#,
                #"src:\s*"([^"]+\.(?:mp4|m3u8)[^"]*)"#,
                #"file:\s*"([^"]+\.(?:mp4|m3u8)[^"]*)"#,
                #"<source[^>]+src="([^"]+\.(?:mp4|m3u8)[^"]*)"#
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let videoUrl = String(html[range])
                    if videoUrl.hasPrefix("http") {
                        completion(.success(videoUrl))
                        return
                    }
                }
            }
            
            completion(.failure(NSError(domain: "CybervynxParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not extract video URL"])))
        }
        
        task.resume()
    }
}