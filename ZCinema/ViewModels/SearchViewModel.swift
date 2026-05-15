import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var searchTask: Task<Void, Never>? = nil
    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] q in
                guard let self else { return }
                if q.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.results = []
                } else {
                    Task { await self.perform(query: q) }
                }
            }
            .store(in: &cancellables)
    }

    private func perform(query: String) async {
        searchTask?.cancel()
        isLoading = true
        errorMessage = nil
        do {
            results = try await Scraper.shared.search(query: query)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }
}
