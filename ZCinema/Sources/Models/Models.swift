import Foundation

// MARK: - Media Item
struct MediaItem: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var imageURL: String
    var rating: String
    var url: String
    var year: String
    var category: String
    var genre: [String]
    var language: String
    var quality: String
    var country: String
    var description: String
    var type: MediaType
    var seasons: [Season]
    
    init(
        id: String = UUID().uuidString,
        title: String,
        imageURL: String,
        rating: String = "8.1",
        url: String,
        year: String = "",
        category: String = "",
        genre: [String] = [],
        language: String = "",
        quality: String = "",
        country: String = "",
        description: String = "",
        type: MediaType = .movie,
        seasons: [Season] = []
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.rating = rating
        self.url = url
        self.year = year
        self.category = category
        self.genre = genre
        self.language = language
        self.quality = quality
        self.country = country
        self.description = description
        self.type = type
        self.seasons = seasons
    }
}

// MARK: - Media Type
enum MediaType: String, Codable, CaseIterable {
    case movie = "movie"
    case series = "series"
    case anime = "anime"
    
    var displayName: String {
        switch self {
        case .movie: return "فيلم"
        case .series: return "مسلسل"
        case .anime: return "انمي"
        }
    }
    
    var icon: String {
        switch self {
        case .movie: return "film"
        case .series: return "tv"
        case .anime: return "sparkles.tv"
        }
    }
}

// MARK: - Season
struct Season: Identifiable, Codable, Hashable {
    let id: String
    var number: Int
    var title: String
    var url: String
    var episodes: [Episode]
    
    init(id: String = UUID().uuidString, number: Int, title: String, url: String, episodes: [Episode] = []) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.episodes = episodes
    }
}

// MARK: - Episode
struct Episode: Identifiable, Codable, Hashable {
    let id: String
    var number: Int
    var title: String
    var url: String
    var servers: [StreamServer]
    
    init(id: String = UUID().uuidString, number: Int, title: String, url: String, servers: [StreamServer] = []) {
        self.id = id
        self.number = number
        self.title = title
        self.url = url
        self.servers = servers
    }
}

// MARK: - Stream Server
struct StreamServer: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var encodedURL: String
    var quality: String
    
    init(id: String = UUID().uuidString, name: String, encodedURL: String, quality: String = "HD") {
        self.id = id
        self.name = name
        self.encodedURL = encodedURL
        self.quality = quality
    }
    
    var watchURL: String {
        return "https://egibest.ws/watch/?url=\(encodedURL)"
    }
}

// MARK: - Home Section
struct HomeSection: Identifiable {
    let id: String
    var title: String
    var items: [MediaItem]
    var moreURL: String
    
    init(id: String = UUID().uuidString, title: String, items: [MediaItem], moreURL: String = "") {
        self.id = id
        self.title = title
        self.items = items
        self.moreURL = moreURL
    }
}

// MARK: - Resolved Stream
struct ResolvedStream {
    var directURL: String
    var type: StreamType
    var quality: String
    var serverName: String
    
    enum StreamType {
        case mp4
        case m3u8
        case iframe
    }
}

// MARK: - Category
struct MediaCategory: Identifiable {
    let id: String
    var name: String
    var url: String
    
    init(id: String = UUID().uuidString, name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
}
