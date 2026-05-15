import Foundation

// MARK: - MediaType
enum MediaType: String, CaseIterable {
    case movie  = "movie"
    case series = "series"
    case anime  = "anime"

    var displayName: String {
        switch self {
        case .movie:  return "فيلم"
        case .series: return "مسلسل"
        case .anime:  return "انمي"
        }
    }

    var pageURL: String {
        switch self {
        case .movie:  return "https://egibest.ws/movies/"
        case .series: return "https://egibest.ws/series/"
        case .anime:  return "https://egibest.ws/category/anime/"
        }
    }
}

// MARK: - MediaItem
struct MediaItem: Identifiable, Hashable {
    let id: String
    var title: String
    var posterURL: String
    var rating: String
    var pageURL: String
    var year: String
    var type: MediaType
    var quality: String
    var genres: [String]
    var country: String
    var language: String
    var overview: String
    var seasons: [Season]

    init(
        id: String = UUID().uuidString,
        title: String,
        posterURL: String,
        rating: String = "",
        pageURL: String,
        year: String = "",
        type: MediaType = .movie,
        quality: String = "",
        genres: [String] = [],
        country: String = "",
        language: String = "",
        overview: String = "",
        seasons: [Season] = []
    ) {
        self.id       = id
        self.title    = title
        self.posterURL = posterURL
        self.rating   = rating
        self.pageURL  = pageURL
        self.year     = year
        self.type     = type
        self.quality  = quality
        self.genres   = genres
        self.country  = country
        self.language = language
        self.overview = overview
        self.seasons  = seasons
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: MediaItem, r: MediaItem) -> Bool { l.id == r.id }
}

// MARK: - Season
struct Season: Identifiable, Hashable {
    let id: String
    var number: Int
    var title: String
    var episodes: [Episode]

    init(id: String = UUID().uuidString, number: Int, title: String, episodes: [Episode] = []) {
        self.id       = id
        self.number   = number
        self.title    = title
        self.episodes = episodes
    }
}

// MARK: - Episode
struct Episode: Identifiable, Hashable {
    let id: String
    var number: Int
    var title: String
    var pageURL: String
    var servers: [StreamServer]

    init(id: String = UUID().uuidString, number: Int, title: String, pageURL: String, servers: [StreamServer] = []) {
        self.id      = id
        self.number  = number
        self.title   = title
        self.pageURL = pageURL
        self.servers = servers
    }
}

// MARK: - StreamServer  (raw encoded entry from the page)
struct StreamServer: Identifiable, Hashable {
    let id: String
    var name: String
    var encodedPayload: String   // base64 or raw URL used in watch?url=

    init(id: String = UUID().uuidString, name: String, encodedPayload: String) {
        self.id             = id
        self.name           = name
        self.encodedPayload = encodedPayload
    }
}

// MARK: - ResolvedStream  (actual playable link)
struct ResolvedStream {
    enum Kind { case hls, mp4, iframe }
    var url: String
    var kind: Kind
    var quality: String
}

// MARK: - HomeSection
struct HomeSection: Identifiable {
    let id: String
    var title: String
    var items: [MediaItem]

    init(id: String = UUID().uuidString, title: String, items: [MediaItem]) {
        self.id    = id
        self.title = title
        self.items = items
    }
}
