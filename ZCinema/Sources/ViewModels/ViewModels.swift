import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var sections: [HomeSection] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    
    func fetchHome() async {
        isLoading = true
        error = nil
        do {
            let fetched = try await EgyBestScraper.shared.fetchHome()
            sections = fetched
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

@MainActor
class MediaListViewModel: ObservableObject {
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: String? = nil
    @Published var currentPage = 1
    @Published var hasMore = true
    
    let mediaType: MediaType
    
    init(mediaType: MediaType) {
        self.mediaType = mediaType
    }
    
    func fetchInitial() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        currentPage = 1
        do {
            let fetched = try await fetchPage(1)
            items = fetched
            hasMore = !fetched.isEmpty
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let nextPage = currentPage + 1
        do {
            let fetched = try await fetchPage(nextPage)
            if fetched.isEmpty {
                hasMore = false
            } else {
                items.append(contentsOf: fetched)
                currentPage = nextPage
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingMore = false
    }
    
    private func fetchPage(_ page: Int) async throws -> [MediaItem] {
        switch mediaType {
        case .movie:
            return try await EgyBestScraper.shared.fetchMovies(page: page)
        case .series:
            return try await EgyBestScraper.shared.fetchSeries(page: page)
        case .anime:
            return try await EgyBestScraper.shared.fetchAnime(page: page)
        }
    }
}

@MainActor
class DetailViewModel: ObservableObject {
    @Published var item: MediaItem?
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var resolvedStream: ResolvedStream? = nil
    @Published var isResolvingStream = false
    @Published var selectedSeason: Season? = nil
    @Published var selectedEpisode: Episode? = nil
    
    func fetchDetail(url: String) async {
        isLoading = true
        error = nil
        do {
            let fetched = try await EgyBestScraper.shared.fetchMediaDetail(url: url)
            item = fetched
            selectedSeason = fetched.seasons.first
            selectedEpisode = fetched.seasons.first?.episodes.first
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
    
    func fetchEpisodeDetail(episode: Episode) async {
        isResolvingStream = true
        resolvedStream = nil
        
        // If episode has no servers, fetch the episode page first
        var servers = episode.servers
        if servers.isEmpty {
            if let detail = try? await EgyBestScraper.shared.fetchMediaDetail(url: episode.url) {
                servers = detail.seasons.first?.episodes.first?.servers ?? []
            }
        }
        
        if !servers.isEmpty {
            resolvedStream = await StreamResolver.shared.resolveBestStream(from: servers)
        }
        
        isResolvingStream = false
    }
    
    func selectEpisode(_ episode: Episode) {
        selectedEpisode = episode
        Task {
            await fetchEpisodeDetail(episode: episode)
        }
    }
    
    func selectSeason(_ season: Season) {
        selectedSeason = season
        selectedEpisode = season.episodes.first
        if let ep = season.episodes.first {
            Task { await fetchEpisodeDetail(episode: ep) }
        }
    }
}

@MainActor
class SearchViewModel: ObservableObject {
    @Published var results: [MediaItem] = []
    @Published var isLoading = false
    @Published var query = ""
    @Published var error: String? = nil
    
    private var searchTask: Task<Void, Never>?
    
    func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // debounce 0.5s
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }
    
    private func performSearch() async {
        isLoading = true
        error = nil
        do {
            results = try await EgyBestScraper.shared.search(query: query)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
