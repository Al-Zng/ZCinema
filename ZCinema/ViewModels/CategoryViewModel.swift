import Foundation

@MainActor
final class CategoryViewModel: ObservableObject {
    let type: MediaType
    @Published var items: [MediaItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String? = nil
    private var page = 1
    private var hasMore = true

    init(type: MediaType) { self.type = type }

    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        page = 1
        hasMore = true
        do {
            let fetched = try await Scraper.shared.fetchList(type: type, page: 1)
            items = fetched
            hasMore = !fetched.isEmpty
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func loadMore() async {
        guard !isLoadingMore, hasMore else { return }
        isLoadingMore = true
        let next = page + 1
        do {
            let fetched = try await Scraper.shared.fetchList(type: type, page: next)
            if fetched.isEmpty {
                hasMore = false
            } else {
                // Deduplicate
                let existingURLs = Set(items.map(\.pageURL))
                let newItems = fetched.filter { !existingURLs.contains($0.pageURL) }
                items.append(contentsOf: newItems)
                page = next
            }
        } catch { /* silently ignore paginate errors */ }
        isLoadingMore = false
    }
}
