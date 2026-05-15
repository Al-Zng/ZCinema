import SwiftUI

struct ContentDetailView: View {
    let content: ContentItem
    @EnvironmentObject var scraperService: ScraperService
    @Environment(\.dismiss) var dismiss
    @State private var loadedDetail: ContentItem?
    @State private var isLoading = true
    @State private var showPlayer = false
    @State private var selectedEpisode: Episode?
    @State private var servers: [VideoServer] = []
    @State private var selectedServer: VideoServer?
    
    var displayItem: ContentItem {
        loadedDetail ?? content
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero Image
                    AsyncImage(url: URL(string: displayItem.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if phase.error != nil {
                            Color.gray
                                .overlay(Image(systemName: "photo"))
                        } else {
                            Color.gray
                                .overlay(ProgressView())
                        }
                    }
                    .frame(height: 450)
                    .clipped()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(displayItem.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let year = displayItem.year {
                            Text(year)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        if let genres = displayItem.genres {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(genres, id: \.self) { genre in
                                        Text(genre)
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.3))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        if let description = displayItem.description {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 8)
                        }
                        
                        // Watch Now Button
                        Button(action: {
                            if displayItem.type == .series {
                                if let firstEpisode = displayItem.seasons?.first?.episodes.first {
                                    selectedEpisode = firstEpisode
                                    showPlayer = true
                                }
                            } else {
                                showPlayer = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("مشاهدة الآن")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                        
                        // Episodes for series
                        if displayItem.type == .series, let seasons = displayItem.seasons {
                            EpisodeListView(seasons: seasons, onEpisodeSelected: { episode in
                                selectedEpisode = episode
                                showPlayer = true
                            })
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding(.top, 50)
                    .padding(.leading, 16)
            }
        }
        .task {
            await loadDetail()
        }
        .fullScreenCover(isPresented: $showPlayer, content: {
            if let episode = selectedEpisode {
                VideoPlayerView(episodeUrl: episode.url, title: "\(displayItem.title) - الحلقة \(episode.episodeNumber)")
                    .environmentObject(scraperService)
            } else if displayItem.type == .movie {
                VideoPlayerView(episodeUrl: displayItem.url, title: displayItem.title)
                    .environmentObject(scraperService)
            }
        })
    }
    
    private func loadDetail() async {
        isLoading = true
        if let detail = await scraperService.loadContentDetail(urlPath: content.url) {
            loadedDetail = detail
        }
        isLoading = false
    }
}