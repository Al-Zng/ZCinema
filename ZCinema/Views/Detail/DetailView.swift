import SwiftUI

struct DetailView: View {
    let pageURL: String
    let title: String

    @StateObject private var vm = DetailViewModel()
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()

            if vm.isLoading {
                loadingState
            } else if let err = vm.errorMessage {
                ErrorState(message: err) { Task { await vm.load(url: pageURL) } }
            } else if let item = vm.detail {
                mainContent(item)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.08, green: 0.08, blue: 0.08), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await vm.load(url: pageURL) }
        .fullScreenCover(isPresented: $showPlayer) {
            if let stream = vm.resolvedStream {
                PlayerView(stream: stream, detailVM: vm)
            }
        }
        .onChange(of: vm.resolvedStream) { stream in
            if stream != nil { showPlayer = true }
        }
    }

    // MARK: - Main content
    private func mainContent(_ item: MediaItem) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroBanner(item)

                VStack(alignment: .leading, spacing: 18) {
                    titleBlock(item)
                    playButton(item)

                    if !item.overview.isEmpty {
                        overviewBlock(item.overview)
                    }

                    metaBlock(item)

                    if !item.seasons.isEmpty && item.type != .movie {
                        episodesBlock(item)
                    }
                }
                .padding(16)
            }
        }
    }

    // MARK: - Hero
    private func heroBanner(_ item: MediaItem) -> some View {
        ZStack(alignment: .bottom) {
            PosterImage(url: item.posterURL, radius: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 270)
                .clipped()

            LinearGradient(
                colors: [.clear, Color(red: 0.07, green: 0.07, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
        }
        .frame(height: 270)
    }

    // MARK: - Title block
    private func titleBlock(_ item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.system(size: 21, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if !item.year.isEmpty {
                    Label(item.year, systemImage: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.65))
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
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text(item.rating)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(white: 0.85))
                    }
                }

                Spacer()

                Text(item.type.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.17))
                    .foregroundColor(Color(white: 0.75))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Play button
    private func playButton(_ item: MediaItem) -> some View {
        Button {
            triggerPlay(item)
        } label: {
            HStack(spacing: 10) {
                if vm.isResolving {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 15, weight: .bold))
                }

                Text(vm.isResolving ? "جاري التحضير..." : "مشاهدة الآن")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(vm.isResolving ? Color(white: 0.75) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .disabled(vm.isResolving)

        // Resolve error inline
        if let err = vm.resolveError {
            Text(err)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.3))
                .padding(.top, -8)
        }
    }

    // MARK: - Overview
    private func overviewBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("القصة", systemImage: "text.alignright")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.72))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Meta
    private func metaBlock(_ item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            if !item.genres.isEmpty {
                metaRow("النوع", value: item.genres.joined(separator: " · "))
            }
            if !item.country.isEmpty  { metaRow("الدولة", value: item.country) }
            if !item.language.isEmpty { metaRow("اللغة",  value: item.language) }
        }
        .padding(13)
        .background(Color(white: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func metaRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(white: 0.45))
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.82))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    // MARK: - Episodes block
    private func episodesBlock(_ item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("الحلقات")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            // Season tabs (if > 1)
            if item.seasons.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(item.seasons) { season in
                            Button {
                                vm.selectSeason(season)
                            } label: {
                                Text(season.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        vm.selectedSeason?.id == season.id
                                            ? Color(red: 0.9, green: 0.1, blue: 0.1)
                                            : Color(white: 0.17)
                                    )
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }

            // Episode rows
            if let season = vm.selectedSeason {
                LazyVStack(spacing: 7) {
                    ForEach(season.episodes) { ep in
                        EpisodeRow(
                            episode: ep,
                            isSelected: vm.selectedEpisode?.id == ep.id,
                            isResolving: vm.isResolving && vm.selectedEpisode?.id == ep.id,
                            onTap: { vm.selectEpisode(ep) }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers
    private func triggerPlay(_ item: MediaItem) {
        // If stream already resolved, open player immediately
        if vm.resolvedStream != nil {
            showPlayer = true
            return
        }
        // Otherwise start resolving
        if let ep = vm.selectedEpisode {
            vm.selectEpisode(ep)
        } else if let ep = item.seasons.first?.episodes.first {
            vm.selectEpisode(ep)
        }
    }

    // MARK: - Loading
    private var loadingState: some View {
        VStack(spacing: 18) {
            ProgressView()
                .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
                .scaleEffect(1.4)
            Text("جاري التحميل...")
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.45))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Episode Row
struct EpisodeRow: View {
    let episode: Episode
    let isSelected: Bool
    let isResolving: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Number box
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected
                              ? Color(red: 0.9, green: 0.1, blue: 0.1)
                              : Color(white: 0.17))
                        .frame(width: 44, height: 44)

                    if isResolving {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.7)
                    } else {
                        Text("\(episode.number)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(episode.title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Text("الحلقة \(episode.number)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                Image(systemName: isSelected ? "play.circle.fill" : "play.circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected
                                     ? Color(red: 0.9, green: 0.1, blue: 0.1)
                                     : Color(white: 0.35))
            }
            .padding(12)
            .background(Color(white: isSelected ? 0.15 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected
                            ? Color(red: 0.9, green: 0.1, blue: 0.1).opacity(0.45)
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
