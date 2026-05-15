import Foundation

@MainActor
final class DetailViewModel: ObservableObject {
    @Published var detail: MediaItem? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // Player state
    @Published var resolvedStream: ResolvedStream? = nil
    @Published var isResolving = false
    @Published var resolveError: String? = nil

    // Episode navigation
    @Published var selectedSeason: Season? = nil
    @Published var selectedEpisode: Episode? = nil

    private var resolveTask: Task<Void, Never>? = nil

    // ─── Load detail page ─────────────────────────────────────────
    func load(url: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            var item = try await Scraper.shared.fetchDetail(url: url)
            detail = item
            // Auto-select first season + first episode
            selectedSeason  = item.seasons.first
            selectedEpisode = item.seasons.first?.episodes.first
            // Auto-start resolving first episode
            if let ep = selectedEpisode {
                await resolveEpisode(ep)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // ─── Select episode ───────────────────────────────────────────
    func selectEpisode(_ ep: Episode) {
        selectedEpisode = ep
        resolveTask?.cancel()
        resolveTask = Task { await resolveEpisode(ep) }
    }

    func selectSeason(_ s: Season) {
        selectedSeason = s
        if let ep = s.episodes.first { selectEpisode(ep) }
    }

    // ─── Resolve stream for an episode ───────────────────────────
    func resolveEpisode(_ ep: Episode) async {
        isResolving = true
        resolveError = nil
        resolvedStream = nil

        // If episode already has servers, use them
        var servers = ep.servers

        // Otherwise fetch the episode page
        if servers.isEmpty {
            servers = (try? await Scraper.shared.fetchServers(url: ep.pageURL)) ?? []
        }

        guard !servers.isEmpty else {
            resolveError = "لا توجد سيرفرات متاحة"
            isResolving = false
            return
        }

        if Task.isCancelled { isResolving = false; return }

        let stream = await StreamResolver.shared.resolve(servers: servers)

        if Task.isCancelled { isResolving = false; return }

        if let s = stream {
            resolvedStream = s
        } else {
            resolveError = "تعذّر استخراج رابط المشاهدة"
        }
        isResolving = false
    }

    // ─── Episode navigation helpers ───────────────────────────────
    var canGoNext: Bool {
        guard let season = selectedSeason,
              let ep = selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id })
        else { return false }
        return idx < season.episodes.count - 1
    }

    var canGoPrev: Bool {
        guard let season = selectedSeason,
              let ep = selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id })
        else { return false }
        return idx > 0
    }

    func goNext() {
        guard canGoNext,
              let season = selectedSeason,
              let ep = selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id })
        else { return }
        selectEpisode(season.episodes[idx + 1])
    }

    func goPrev() {
        guard canGoPrev,
              let season = selectedSeason,
              let ep = selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id })
        else { return }
        selectEpisode(season.episodes[idx - 1])
    }
}
