import SwiftUI

struct CategoryListView: View {
    let type: MediaType
    @StateObject private var vm: CategoryViewModel

    private let columns = [GridItem(.adaptive(minimum: 108, maximum: 130), spacing: 10)]

    init(type: MediaType) {
        self.type = type
        _vm = StateObject(wrappedValue: CategoryViewModel(type: type))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()

                if vm.isLoading && vm.items.isEmpty {
                    loadingGrid
                } else if let err = vm.errorMessage, vm.items.isEmpty {
                    ErrorState(message: err) { Task { await vm.loadInitial() } }
                } else {
                    grid
                }
            }
            .navigationTitle(type.displayName + "s" == "movies" ? "أفلام" : type.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.08), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .task { if vm.items.isEmpty { await vm.loadInitial() } }
    }

    // ─── Grid ─────────────────────────────────────────────────────
    private var grid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(vm.items) { item in
                    MediaCard(item: item, width: 115, height: 168)
                        .onAppear {
                            if item.id == vm.items.last?.id {
                                Task { await vm.loadMore() }
                            }
                        }
                }
            }
            .padding(14)

            if vm.isLoadingMore {
                ProgressView()
                    .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
                    .padding(.bottom, 20)
            }
        }
        .refreshable { await vm.loadInitial() }
    }

    // ─── Loading ──────────────────────────────────────────────────
    private var loadingGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<16, id: \.self) { _ in SkeletonCard() }
            }
            .padding(14)
        }
    }
}
