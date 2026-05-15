import SwiftUI
import AVKit
import WebKit

struct VideoPlayerView: View {
    let episodeUrl: String
    let title: String
    @EnvironmentObject var scraperService: ScraperService
    @Environment(\.dismiss) var dismiss
    @State private var videoUrl: String?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var servers: [VideoServer] = []
    @State private var selectedServer: VideoServer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                VStack {
                    ProgressView()
                        .tint(.red)
                    Text("جاري تحميل الفيديو...")
                        .foregroundColor(.white)
                        .padding()
                }
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    Text(error)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    Button("إعادة المحاولة") {
                        Task { await loadVideo() }
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    
                    // Server selection
                    if !servers.isEmpty {
                        Text("اختر سيرفر آخر")
                            .foregroundColor(.white)
                            .padding(.top)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(servers) { server in
                                    Button(server.name) {
                                        selectServer(server)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedServer?.id == server.id ? Color.red : Color.gray.opacity(0.3))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
            } else if let videoUrl = videoUrl {
                VideoPlayerController(videoURL: URL(string: videoUrl)!)
                    .ignoresSafeArea()
                    .overlay(alignment: .topLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .padding(12)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(.top, 50)
                                .padding(.leading, 16)
                        }
                    }
            }
        }
        .task {
            await loadServers()
        }
        .navigationBarHidden(true)
    }
    
    private func loadServers() async {
        isLoading = true
        let fetchedServers = await scraperService.loadEpisodeServers(episodeUrl: episodeUrl)
        servers = fetchedServers
        if let first = servers.first {
            selectedServer = first
            await loadVideoFromServer(first)
        } else {
            errorMessage = "لا توجد سيرفرات متاحة"
            isLoading = false
        }
    }
    
    private func selectServer(_ server: VideoServer) {
        selectedServer = server
        isLoading = true
        errorMessage = nil
        Task {
            await loadVideoFromServer(server)
        }
    }
    
    private func loadVideoFromServer(_ server: VideoServer) async {
        let embedUrl = server.embedUrl
        // Determine host from URL
        let host: ServerHost?
        if embedUrl.contains("doodstream") {
            host = .doodstream
        } else if embedUrl.contains("mixdrop") {
            host = .mixdrop
        } else if embedUrl.contains("streamtape") {
            host = .streamtape
        } else if embedUrl.contains("cybervynx") || embedUrl.contains("lulustream") {
            host = .cybervynx
        } else {
            host = nil
        }
        
        if let host = host {
            let directUrl = await scraperService.extractDirectVideoUrl(from: embedUrl, host: host)
            await MainActor.run {
                if let url = directUrl {
                    self.videoUrl = url
                    self.isLoading = false
                } else {
                    self.errorMessage = "فشل استخراج رابط الفيديو"
                    self.isLoading = false
                }
            }
        } else {
            // For unknown hosts, try to use embed URL directly if it's a video
            if embedUrl.hasSuffix(".mp4") || embedUrl.hasSuffix(".m3u8") {
                self.videoUrl = embedUrl
                self.isLoading = false
            } else {
                self.errorMessage = "سيرفر غير مدعوم: \(server.name)"
                self.isLoading = false
            }
        }
    }
    
    private func loadVideo() async {
        if let server = selectedServer {
            await loadVideoFromServer(server)
        } else {
            await loadServers()
        }
    }
}

struct VideoPlayerController: UIViewControllerRepresentable {
    let videoURL: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: videoURL)
        controller.player = player
        controller.showsPlaybackControls = true
        controller.entersFullScreenWhenPlaybackBegins = true
        controller.exitsFullScreenWhenPlaybackEnds = false
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}