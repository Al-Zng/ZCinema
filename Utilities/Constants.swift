import Foundation

enum Constants {
    static let baseURL = "https://egibest.ws"
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    
    static let categoryMapping: [String: String] = [
        "افلام": "/movies/",
        "مسلسلات": "/series/",
        "انمى": "/category/anime/",
        "افلام 2025": "/movies/?year=2025",
        "أفضل مسلسلات هذا الشهر": "/trending/"
    ]
}