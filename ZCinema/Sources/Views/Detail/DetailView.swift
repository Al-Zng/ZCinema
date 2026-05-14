import SwiftUI

struct DetailView: View {
    let item: MediaItem
    @StateObject private var vm = DetailViewModel()
    @State private var showPlayer = false
    
    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
            
            if vm.isLoading {
                loadingView
            } else if let detail = vm.item {
                detailContent(detail)
            } else {
                loadingView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.07, green: 0.07, blue: 0.07), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await vm.fetchDetail(url: item.url)
        }
        .fullScreenCover(isPresented: $showPlayer) {
            if let stream = vm.resolvedStream {
                PlayerView(stream: stream, item: vm.item ?? item, vm: vm)
            }
        }
        .onChange(of: vm.resolvedStream) { stream in
            if stream != nil {
                showPlayer = true
            }
        }
    }
    
    // MARK: - Detail Content
    private func detailContent(_ detail: MediaItem) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero Image
                heroImage(detail)
                
                // Info
                VStack(alignment: .leading, spacing: 20) {
                    // Title & Meta
                    titleSection(detail)
                    
                    // Play Button
                    playButton(detail)
                    
                    // Description
                    if !detail.description.isEmpty {
                        descriptionSection(detail.description)
                    }
                    
                    // Meta Info
                    metaSection(detail)
                    
                    // Episodes (if series/anime)
                    if detail.type != .movie && !detail.seasons.isEmpty {
                        episodesSection(detail)
                    }
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Hero Image
    private func heroImage(_ detail: MediaItem) -> some View {
        ZStack(alignment: .bottom) {
            ZCinemaImage(url: detail.imageURL, contentMode: .fill, cornerRadius: 0)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .clipped()
            
            LinearGradient(
                colors: [.clear, Color(red: 0.07, green: 0.07, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
        }
        .frame(height: 280)
    }
    
    // MARK: - Title
    private func titleSection(_ detail: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detail.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 12) {
                if !detail.year.isEmpty {
                    Label(detail.year, systemImage: "calendar")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.7))
                }
                
                if !detail.quality.isEmpty {
                    Text(detail.quality)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(red: 0.9, green: 0.1, blue: 0.1))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    Text(detail.rating)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(white: 0.85))
                }
                
                Spacer()
                
                // Type pill
                Text(detail.type.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.18))
                    .foregroundColor(Color(white: 0.8))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - Play Button
    private func playButton(_ detail: MediaItem) -> some View {
        Button {
            handlePlay(detail)
        } label: {
            HStack(spacing: 10) {
                if vm.isResolvingStream {
                    ProgressView()
                        .tint(.black)
                        .scaleEffect(0.85)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                Text(vm.isResolvingStream ? "جاري التحميل..." : "مشاهدة الآن")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(vm.isResolvingStream)
    }
    
    // MARK: - Description
    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("القصة")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.75))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Meta Info
    private func metaSection(_ detail: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !detail.genre.isEmpty {
                metaRow(label: "النوع", value: detail.genre.joined(separator: " • "))
            }
            if !detail.country.isEmpty {
                metaRow(label: "الدولة", value: detail.country)
            }
            if !detail.language.isEmpty {
                metaRow(label: "اللغة", value: detail.language)
            }
            if !detail.category.isEmpty {
                metaRow(label: "القسم", value: detail.category)
            }
        }
        .padding(14)
        .background(Color(white: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func metaRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.85))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }
    
    // MARK: - Episodes Section
    private func episodesSection(_ detail: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("الحلقات")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
            
            // Season tabs
            if detail.seasons.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(detail.seasons) { season in
                            Button {
                                vm.selectSeason(season)
                            } label: {
                                Text(season.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(vm.selectedSeason?.id == season.id
                                        ? Color(red: 0.9, green: 0.1, blue: 0.1)
                                        : Color(white: 0.18))
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            
            // Episode list
            if let season = vm.selectedSeason {
                LazyVStack(spacing: 8) {
                    ForEach(season.episodes) { episode in
                        EpisodeRow(
                            episode: episode,
                            isSelected: vm.selectedEpisode?.id == episode.id,
                            isLoading: vm.isResolvingStream && vm.selectedEpisode?.id == episode.id
                        ) {
                            vm.selectEpisode(episode)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func handlePlay(_ detail: MediaItem) {
        if let episode = vm.selectedEpisode {
            vm.selectEpisode(episode)
        } else if let firstEp = detail.seasons.first?.episodes.first {
            vm.selectEpisode(firstEp)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color(red: 0.9, green: 0.1, blue: 0.1))
                .scaleEffect(1.3)
            Text("جاري التحميل...")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Episode Row
struct EpisodeRow: View {
    let episode: Episode
    let isSelected: Bool
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Episode number
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color(white: 0.18))
                        .frame(width: 44, height: 44)
                    
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.75)
                    } else {
                        Text("\(episode.number)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(episode.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text("الحلقة \(episode.number)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.55))
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "play.circle.fill" : "play.circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color(white: 0.4))
            }
            .padding(12)
            .background(Color(white: isSelected ? 0.16 : 0.10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color(red: 0.9, green: 0.1, blue: 0.1).opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
