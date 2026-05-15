import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()

                if vm.isLoading && vm.sections.isEmpty {
                    loadingState
                } else if let err = vm.errorMessage, vm.sections.isEmpty {
                    ErrorState(message: err) { Task { await vm.reload() } }
                } else {
                    content
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { logoToolbar }
            .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.07), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .task { if vm.sections.isEmpty { await vm.load() } }
    }

    // ─── Main content ─────────────────────────────────────────────
    private var content: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 22) {
                // Hero carousel (first section)
                if let hero = vm.sections.first {
                    HeroCarousel(items: Array(hero.items.prefix(6)))
                        .padding(.top, 6)
                }

                // Remaining sections
                ForEach(vm.sections) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: section.title)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(alignment: .top, spacing: 10) {
                                ForEach(section.items) { item in
                                    MediaCard(item: item)
                                }
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable { await vm.reload() }
    }

    // ─── Loading ──────────────────────────────────────────────────
    private var loadingState: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 22) {
                // hero skeleton
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(white: 0.14))
                    .frame(height: 210)
                    .shimmer()
                    .padding(.horizontal, 14)

                ForEach(0..<4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(white: 0.16))
                            .frame(width: 130, height: 14)
                            .shimmer()
                            .padding(.horizontal, 14)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(0..<7, id: \.self) { _ in SkeletonCard() }
                            }
                            .padding(.horizontal, 14)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
    }

    // ─── Toolbar ──────────────────────────────────────────────────
    private var logoToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("ZCinema")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
        }
    }
}

// MARK: - Hero Carousel
struct HeroCarousel: View {
    let items: [MediaItem]
    @State private var current = 0
    @State private var timer: Timer? = nil

    var body: some View {
        TabView(selection: $current) {
            ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                HeroCard(item: item)
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .frame(height: 215)
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
            withAnimation { current = (current + 1) % max(1, items.count) }
        }
    }
}

struct HeroCard: View {
    let item: MediaItem

    var body: some View {
        NavigationLink(destination: DetailView(pageURL: item.pageURL, title: item.title)) {
            ZStack(alignment: .bottomLeading) {
                PosterImage(url: item.posterURL, radius: 14)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.82)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        if !item.year.isEmpty {
                            Label(item.year, systemImage: "calendar")
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.8))
                        }
                        if !item.quality.isEmpty {
                            Text(item.quality)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        if !item.rating.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text(item.rating)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 14)
    }
}

// MARK: - Error State (reusable)
struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(Color(white: 0.35))

            Text("تعذّر التحميل")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: retry) {
                Text("إعادة المحاولة")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 26)
                    .padding(.vertical, 11)
                    .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
