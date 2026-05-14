import SwiftUI

// MARK: - Movies Tab
struct MoviesView: View {
    var body: some View {
        MediaListView(mediaType: .movie, title: "أفلام", icon: "film.fill")
    }
}

// MARK: - Series Tab
struct SeriesView: View {
    var body: some View {
        MediaListView(mediaType: .series, title: "مسلسلات", icon: "tv.fill")
    }
}

// MARK: - Anime Tab
struct AnimeView: View {
    var body: some View {
        MediaListView(mediaType: .anime, title: "انمي", icon: "sparkles.tv.fill")
    }
}

// MARK: - Generic Grid List
struct MediaListView: View {
    @StateObject private var vm: MediaListViewModel
    let title: String
    let icon: String

    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 145), spacing: 10)]

    init(mediaType: MediaType, title: String, icon: String) {
        _vm = StateObject(wrappedValue: MediaListViewModel(mediaType: mediaType))
        self.title = title
        self.icon = icon
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
                if vm.isLoading && vm.items.isEmpty {
                    loadingGrid
                } else if let error = vm.error, vm.items.isEmpty {
                    errorView(error)
                } else {
                    gridContent
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .task { await vm.fetchInitial() }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var gridContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(vm.items) { item in
                    MediaCard(item: item)
                        .onAppear {
                            if item.id == vm.items.last?.id {
                                Task { await vm.fetchMore() }
                            }
                        }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            if vm.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView().progressViewStyle(.circular).tint(.white)
                    Spacer()
                }
                .padding(.vertical, 20)
            }

            Spacer(minLength: 50)
        }
        .refreshable { await vm.fetchInitial() }
    }

    private var loadingGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<12, id: \.self) { _ in SkeletonCard() }
            }
            .padding(.horizontal, 14).padding(.top, 10)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44)).foregroundColor(Color(white: 0.35))
            Text("فشل التحميل").font(.system(size: 17, weight: .semibold)).foregroundColor(.white)
            Text(message).font(.system(size: 13)).foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Button { Task { await vm.fetchInitial() } } label: {
                HStack(spacing: 7) {
                    Image(systemName: "arrow.clockwise")
                    Text("إعادة المحاولة")
                }
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(Color(red:0.9,green:0.1,blue:0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

// MARK: - Search View
struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    private let columns = [GridItem(.adaptive(minimum: 110, maximum: 145), spacing: 10)]

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    if vm.query.isEmpty {
                        emptyPrompt
                    } else if vm.isLoading {
                        loadingView
                    } else if vm.results.isEmpty {
                        noResults
                    } else {
                        resultsGrid
                    }
                }
            }
            .navigationTitle("بحث")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(white: 0.5)).font(.system(size: 16))
            TextField("ابحث عن فيلم أو مسلسل...", text: $vm.query)
                .foregroundColor(.white)
                .font(.system(size: 15))
                .autocorrectionDisabled()
                .onChange(of: vm.query) { _ in vm.search() }
            if !vm.query.isEmpty {
                Button { vm.query = ""; vm.results = [] } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(white: 0.4)).font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Color(white: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var emptyPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "film.stack").font(.system(size: 52)).foregroundColor(Color(white: 0.25))
            Text("ابحث عن أي محتوى").font(.system(size: 16, weight: .medium)).foregroundColor(Color(white: 0.4))
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack { Spacer(); ProgressView().progressViewStyle(.circular).tint(.white).scaleEffect(1.3); Spacer() }
    }

    private var noResults: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "magnifyingglass").font(.system(size: 44)).foregroundColor(Color(white: 0.3))
            Text("لا توجد نتائج لـ «\(vm.query)»")
                .font(.system(size: 15)).foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }

    private var resultsGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(vm.results) { item in MediaCard(item: item) }
            }
            .padding(.horizontal, 14).padding(.top, 6)
            Spacer(minLength: 50)
        }
    }
}
