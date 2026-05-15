import Foundation

struct StreamtapeParser: VideoParser {
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
            
            // Streamtape pattern: look for getVideo() or direct video link
            // Also look for robotlink
            let patterns = [
                #"robotlink\s*=\s*'([^']+)'"#,
                #"robotlink\s*=\s*"([^"]+)""#,
                #"getVideo\('[^']+','([^']+)'\)"#,
                #"<video[^>]+src="([^"]+)"#,
                #"src:\s*"([^"]+\.mp4[^"]*)"#
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    var videoUrl = String(html[range])
                    if !videoUrl.hasPrefix("http") && videoUrl.hasPrefix("/") {
                        videoUrl = "https://streamtape.com" + videoUrl
                    }
                    if videoUrl.hasPrefix("http") {
                        completion(.success(videoUrl))
                        return
                    }
                }
            }
            
            completion(.failure(NSError(domain: "StreamtapeParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not extract video URL"])))
        }
        
        task.resume()
    }
}