import Foundation

struct ContentItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let url: String
    let imageUrl: String
    let type: ContentType
    let rating: String?
    let year: String?
    let description: String?
    let genres: [String]?
    let seasons: [Season]?
    
    enum ContentType: String, Codable {
        case movie, series, anime
    }
}

extension ContentItem {
    static let mockMovie = ContentItem(
        title: "The Punisher: One Last Kill",
        url: "/film-the-punisher-one-last-kill-2026",
        imageUrl: "https://egibest.ws/wp-content/uploads/2026/05/MV5BYzdhZTI5YWQtOTE5ZS00YmE1LTgxOWUtN2ZiMzYwOGU5OWNhXkEyXkFqcGc@-439x650-64693.jpg",
        type: .movie,
        rating: "8.1",
        year: "2026",
        description: "المنتقم يعود في مغامرة أخيرة...",
        genres: ["أكشن", "إثارة"],
        seasons: nil
    )
    
    static let mockSeries = ContentItem(
        title: "Widow's Bay",
        url: "/مشاهدة-مسلسل-widows-bay-الموسم-الاول-الحلقة-4",
        imageUrl: "https://egibest.ws/wp-content/uploads/2026/05/MV5BYzE4ZDNkZWQtYTNmNy00MjQwLTk0ODItN2YyYWUwYzEzNzk2XkEyXkFqcGc@._V1_-scaled-433x650-64703.jpg",
        type: .series,
        rating: "8.1",
        year: "2026",
        description: "يتبع العمل قصة عمدة متشكك يقود سكان جزيرة ملعونة...",
        genres: ["دراما", "رعب", "كوميدي"],
        seasons: nil
    )
}