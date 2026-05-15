import Foundation

struct DoodstreamParser: VideoParser {
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
            
            // Doodstream direct video extraction
            // Look for 'src: "https://..."' or video element
            let patterns = [
                #"src:\s*"([^"]+\.mp4[^"]*)"#,
                #"src:\s*'([^']+\.mp4[^']*)'"#,
                #"<video[^>]+src="([^"]+\.mp4[^"]*)"#,
                #"file:\s*"([^"]+\.mp4[^"]*)"#,
                #"file:\s*'([^']+\.mp4[^']*)'"#
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: []),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..<html.endIndex, in: html)),
                   let range = Range(match.range(at: 1), in: html) {
                    let videoUrl = String(html[range])
                    completion(.success(videoUrl))
                    return
                }
            }
            
            // If not found, use the embed URL itself (some servers redirect)
            completion(.success(pageUrl))
        }
        
        task.resume()
    }
}