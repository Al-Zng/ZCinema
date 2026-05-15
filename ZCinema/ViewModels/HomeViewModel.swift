import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var sections: [HomeSection] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            sections = try await Scraper.shared.fetchHome()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func reload() async { await load() }
}
