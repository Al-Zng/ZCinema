import Foundation

struct MixdropParser: VideoParser {
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
            
            // Mixdrop pattern: "return p+"?f"=" + encoded
            // Or look for video source
            let patterns = [
                #"video_url:\s*'([^']+)'"#,
                #"video_url:\s*"([^"]+)""#,
                #"src:\s*"([^"]+\.mp4[^"]*)"#,
                #"<video[^>]+src="([^"]+\.mp4[^"]*)"#
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
            
            completion(.failure(NSError(domain: "MixdropParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not extract video URL"])))
        }
        
        task.resume()
    }
}