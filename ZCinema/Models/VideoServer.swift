import Foundation

struct VideoServer: Identifiable {
    let id = UUID()
    let name: String
    let embedUrl: String
    let downloadUrl: String?
    let quality: String?
}

enum ServerHost: String {
    case doodstream = "doodstream.com"
    case mixdrop = "mixdrop.ps"
    case streamtape = "streamtape.com"
    case cybervynx = "cybervynx.com"
    case lulustream = "lulustream.com"
    
    var parser: VideoParser.Type {
        switch self {
        case .doodstream:
            return DoodstreamParser.self
        case .mixdrop:
            return MixdropParser.self
        case .streamtape:
            return StreamtapeParser.self
        case .cybervynx, .lulustream:
            return CybervynxParser.self
        }
    }
}

protocol VideoParser {
    static func extractVideoUrl(from pageUrl: String, completion: @escaping (Result<String, Error>) -> Void)
}