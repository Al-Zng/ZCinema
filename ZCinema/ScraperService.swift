import Foundation

struct MediaContent: Identifiable {
    let id = UUID()
    let title: String
    let url: String
    let poster: String
    let rating: String
    let isSeries: Bool
}

struct Episode: Identifiable {
    let id = UUID()
    let number: Int
    let videoUrl: String
}

class ScraperService {
    static let shared = ScraperService()
    private let apiBase = "https://egibest.ws/"

    // استخراج المحتوى من القوائم
    func fetchLatest(completion: @escaping ([MediaContent]) -> Void) {
        guard let url = URL(string: apiBase) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
            
            // محاكاة لعملية الكشط بناءً على بنية الموقع
            // يتم استخدام Regex لاستخراج الداتا من الكلاسات: .item, .title, img src
            var results = [MediaContent]()
            let pattern = #"<div class="item">.*?<a href="(.*?)".*?src="(.*?)".*?title">(.*?)</div>"#
            // ... منطق استخراج البيانات الفعلي ...
            completion(results)
        }.resume()
    }

    // استخراج الرابط المباشر m3u8/mp4
    func extractSource(from pageUrl: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: pageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else { return }
            
            // ميكانيكية البحث عن الروابط المباشرة داخل iframe السيرفرات
            let patterns = [
                #"(https?://[^\s"'<>]+?\.m3u8[^\s"'<>]*)"#,
                #"(https?://[^\s"'<>]+?\.mp4[^\s"'<>]*)"#
            ]
            
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                   let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)),
                   let range = Range(match.range, in: html) {
                    let link = String(html[range])
                    DispatchQueue.main.async { completion(link) }
                    return
                }
            }
            completion(nil)
        }.resume()
    }
}
