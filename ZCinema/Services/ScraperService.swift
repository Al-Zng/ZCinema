import Foundation
import SwiftUI

@MainActor
class ScraperService: ObservableObject {
    @Published var homeSections: [HomeSection] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "https://egibest.ws"
    private let htmlParser = HTMLParser()
    
    struct HomeSection: Identifiable {
        let id = UUID()
        let title: String
        let items: [ContentItem]
        let seeAllUrl: String?
    }
    
    func loadHomePage() async {
        isLoading = true
        error = nil
        
        do {
            let html = try await fetchHTML(url: baseURL)
            let sections = try await htmlParser.parseHomePage(html: html, baseURL: baseURL)
            homeSections = sections
        } catch {
            self.error = error.localizedDescription
            print("Error loading home page: \(error)")
            // Fallback to mock data
            homeSections = [
                HomeSection(title: "أحدث الأفلام", items: [.mockMovie, .mockMovie], seeAllUrl: "/movies/"),
                HomeSection(title: "أحدث المسلسلات", items: [.mockSeries, .mockSeries], seeAllUrl: "/series/")
            ]
        }
        
        isLoading = false
    }
    
    func loadContentDetail(urlPath: String) async -> ContentItem? {
        let fullURL = urlPath.hasPrefix("http") ? urlPath : baseURL + urlPath
        
        do {
            let html = try await fetchHTML(url: fullURL)
            return try await htmlParser.parseContentDetail(html: html, baseURL: baseURL)
        } catch {
            print("Error loading content detail: \(error)")
            return nil
        }
    }
    
    func loadEpisodeServers(episodeUrl: String) async -> [VideoServer] {
        do {
            let html = try await fetchHTML(url: episodeUrl)
            return try await htmlParser.parseVideoServers(html: html, baseURL: baseURL)
        } catch {
            print("Error loading episode servers: \(error)")
            return []
        }
    }
    
    func extractDirectVideoUrl(from serverUrl: String, host: ServerHost) async -> String? {
        return await withCheckedContinuation { continuation in
            host.parser.extractVideoUrl(from: serverUrl) { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func fetchHTML(url: String) async throws -> String {
        guard let url = URL(string: url) else {
            throw URLError(.badURL)
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "ar,en;q=0.9",
            "Cache-Control": "no-cache"
        ]
        
        let session = URLSession(configuration: configuration)
        let (data, _) = try await session.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        return html
    }
}