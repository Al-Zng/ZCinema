import Foundation

struct Season: Identifiable, Codable {
    let id = UUID()
    let seasonNumber: Int
    let episodes: [Episode]
}

struct Episode: Identifiable, Codable {
    let id = UUID()
    let episodeNumber: Int
    let title: String
    let url: String
    let thumbnailUrl: String?
}