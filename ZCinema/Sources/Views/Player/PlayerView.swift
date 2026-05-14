import SwiftUI
import AVKit
import AVFoundation

// MARK: - Player View (Full Screen Professional)
struct PlayerView: View {
    let stream: ResolvedStream
    let item: MediaItem
    @ObservedObject var vm: DetailViewModel
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerVM = VideoPlayerViewModel()
    @State private var showControls = true
    @State private var controlsTimer: Timer?
    @State private var showEpisodes = false
    @State private var orientation = UIDeviceOrientation.landscapeLeft
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Player
            playerContent
            
            // Controls overlay
            if showControls {
                controlsOverlay
                    .transition(.opacity)
            }
            
            // Episode panel
            if showEpisodes {
                episodePanel
                    .transition(.move(edge: .trailing))
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
            if showControls { resetControlsTimer() }
        }
        .onAppear {
            playerVM.loadStream(stream)
            resetControlsTimer()
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            playerVM.stop()
            UIApplication.shared.isIdleTimerDisabled = false
            controlsTimer?.invalidate()
        }
        .onChange(of: vm.resolvedStream) { newStream in
            if let s = newStream {
                playerVM.loadStream(s)
            }
        }
    }
    
    // MARK: - Player Content
    private var playerContent: some View {
        Group {
            if stream.type == .iframe {
                // WebView for iframe streams
                WebPlayerView(url: stream.directURL)
                    .ignoresSafeArea()
            } else {
                // Native AVPlayer
                NativeVideoPlayer(player: playerVM.player)
                    .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Controls Overlay
    private var controlsOverlay: some View {
        ZStack {
            // Gradient overlays
            VStack {
                topGradient
                Spacer()
                bottomGradient
            }
            
            // Controls
            VStack(spacing: 0) {
                topBar
                Spacer()
                centerControls
                Spacer()
                bottomBar
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Top Gradient
    private var topGradient: some View {
        LinearGradient(
            colors: [.black.opacity(0.75), .clear],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 120)
    }
    
    // MARK: - Bottom Gradient
    private var bottomGradient: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 130)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let ep = vm.selectedEpisode {
                    Text("الحلقة \(ep.number)")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.75))
                }
            }
            
            Spacer()
            
            // Episode list toggle (for series)
            if item.type != .movie {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showEpisodes.toggle()
                    }
                } label: {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .shadow(radius: 4)
                }
            }
            
            // Lock button
            Button { } label: {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Center Controls
    private var centerControls: some View {
        HStack(spacing: 44) {
            // Previous episode
            if item.type != .movie {
                Button {
                    navigateEpisode(forward: false)
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 26))
                        .foregroundColor(canGoPrevious ? .white : .white.opacity(0.3))
                }
                .disabled(!canGoPrevious)
            }
            
            // Seek back 10s
            Button {
                playerVM.seek(by: -10)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // Play/Pause
            Button {
                playerVM.togglePlayPause()
                resetControlsTimer()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    if playerVM.isLoading {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: playerVM.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .offset(x: playerVM.isPlaying ? 0 : 2)
                    }
                }
            }
            
            // Seek forward 10s
            Button {
                playerVM.seek(by: 10)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }
            
            // Next episode
            if item.type != .movie {
                Button {
                    navigateEpisode(forward: true)
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 26))
                        .foregroundColor(canGoNext ? .white : .white.opacity(0.3))
                }
                .disabled(!canGoNext)
            }
        }
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Progress Slider
            PlayerProgressBar(
                progress: $playerVM.progress,
                buffered: playerVM.buffered,
                duration: playerVM.duration,
                onSeek: { value in
                    playerVM.seekToProgress(value)
                }
            )
            .padding(.horizontal, 20)
            
            // Time & Quality
            HStack {
                Text(formatTime(playerVM.currentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.8))
                
                Spacer()
                
                // Quality badge
                Text(stream.quality)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(red: 0.9, green: 0.1, blue: 0.1).opacity(0.9))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                Text(formatTime(playerVM.duration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.8))
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Episode Panel
    private var episodePanel: some View {
        HStack {
            Spacer()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("الحلقات")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showEpisodes = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color(white: 0.6))
                    }
                }
                .padding(16)
                .background(Color(white: 0.12))
                
                Divider().background(Color(white: 0.2))
                
                // Episode list
                if let season = vm.selectedSeason {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(season.episodes) { episode in
                                PanelEpisodeRow(
                                    episode: episode,
                                    isCurrent: vm.selectedEpisode?.id == episode.id
                                ) {
                                    vm.selectEpisode(episode)
                                    withAnimation {
                                        showEpisodes = false
                                    }
                                }
                                Divider().background(Color(white: 0.15))
                            }
                        }
                    }
                }
            }
            .frame(width: min(UIScreen.main.bounds.width * 0.38, 300))
            .background(Color(white: 0.08))
        }
        .ignoresSafeArea()
        .onTapGesture {
            withAnimation { showEpisodes = false }
        }
    }
    
    // MARK: - Helpers
    private var canGoNext: Bool {
        guard let season = vm.selectedSeason,
              let ep = vm.selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id }) else { return false }
        return idx < season.episodes.count - 1
    }
    
    private var canGoPrevious: Bool {
        guard let season = vm.selectedSeason,
              let ep = vm.selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id }) else { return false }
        return idx > 0
    }
    
    private func navigateEpisode(forward: Bool) {
        guard let season = vm.selectedSeason,
              let ep = vm.selectedEpisode,
              let idx = season.episodes.firstIndex(where: { $0.id == ep.id }) else { return }
        let newIdx = forward ? idx + 1 : idx - 1
        guard newIdx >= 0 && newIdx < season.episodes.count else { return }
        vm.selectEpisode(season.episodes[newIdx])
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite else { return "0:00" }
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }
}

// MARK: - Progress Bar
struct PlayerProgressBar: View {
    @Binding var progress: Double
    let buffered: Double
    let duration: Double
    let onSeek: (Double) -> Void
    
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: isDragging ? 5 : 3)
                
                // Buffer
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.35))
                    .frame(width: geo.size.width * buffered, height: isDragging ? 5 : 3)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                    .frame(width: geo.size.width * (isDragging ? dragValue : progress), height: isDragging ? 5 : 3)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isDragging ? 16 : 12, height: isDragging ? 16 : 12)
                    .shadow(radius: 2)
                    .offset(x: geo.size.width * (isDragging ? dragValue : progress) - (isDragging ? 8 : 6))
                    .animation(.easeInOut(duration: 0.1), value: isDragging)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        isDragging = true
                        dragValue = max(0, min(1, val.location.x / geo.size.width))
                    }
                    .onEnded { val in
                        let finalValue = max(0, min(1, val.location.x / geo.size.width))
                        onSeek(finalValue)
                        isDragging = false
                    }
            )
        }
        .frame(height: 20)
    }
}

// MARK: - Panel Episode Row
struct PanelEpisodeRow: View {
    let episode: Episode
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCurrent ? Color(red: 0.9, green: 0.1, blue: 0.1) : Color(white: 0.2))
                        .frame(width: 36, height: 36)
                    Text("\(episode.number)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(episode.title)
                    .font(.system(size: 13))
                    .foregroundColor(isCurrent ? .white : Color(white: 0.75))
                Spacer()
                if isCurrent {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isCurrent ? Color.white.opacity(0.07) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Native Video Player
struct NativeVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer?
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspect
        vc.view.backgroundColor = .black
        return vc
    }
    
    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {
        if vc.player !== player {
            vc.player = player
        }
    }
}

// MARK: - Web Player (for iframe streams)
struct WebPlayerView: UIViewRepresentable {
    let url: String
    
    func makeUIView(context: Context) -> WKWebViewWrapper {
        let wrapper = WKWebViewWrapper()
        wrapper.loadURL(url)
        return wrapper
    }
    
    func updateUIView(_ uiView: WKWebViewWrapper, context: Context) {
        uiView.loadURL(url)
    }
}

import WebKit

class WKWebViewWrapper: UIView {
    private var webView: WKWebView?
    private var currentURL: String = ""
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupWebView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWebView()
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let wv = WKWebView(frame: bounds, configuration: config)
        wv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wv.scrollView.isScrollEnabled = false
        wv.backgroundColor = .black
        addSubview(wv)
        self.webView = wv
    }
    
    func loadURL(_ urlString: String) {
        guard urlString != currentURL, let url = URL(string: urlString) else { return }
        currentURL = urlString
        var request = URLRequest(url: url)
        request.setValue("https://egibest.ws/", forHTTPHeaderField: "Referer")
        webView?.load(request)
    }
}

// MARK: - Video Player ViewModel
@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = true
    @Published var progress: Double = 0
    @Published var buffered: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var error: String? = nil
    
    var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?
    
    func loadStream(_ stream: ResolvedStream) {
        cleanup()
        isLoading = true
        isPlaying = false
        progress = 0
        currentTime = 0
        duration = 0
        
        guard let url = URL(string: stream.directURL) else {
            error = "رابط غير صحيح"
            isLoading = false
            return
        }
        
        var headers: [String: String] = [
            "Referer": "https://egibest.ws/",
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
        ]
        
        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item = AVPlayerItem(asset: asset)
        
        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = true
        self.player = p
        
        // Observe status
        statusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                switch item.status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.duration = item.duration.seconds
                    p.play()
                    self?.isPlaying = true
                case .failed:
                    self?.isLoading = false
                    self?.error = item.error?.localizedDescription ?? "خطأ في التشغيل"
                default:
                    break
                }
            }
        }
        
        // Time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let current = time.seconds
                let dur = p.currentItem?.duration.seconds ?? 0
                self.currentTime = current
                if dur > 0 && !dur.isNaN {
                    self.duration = dur
                    self.progress = current / dur
                }
                // Buffer
                if let range = p.currentItem?.loadedTimeRanges.first {
                    let bufEnd = CMTimeRangeGetEnd(range.timeRangeValue).seconds
                    if dur > 0 { self.buffered = bufEnd / dur }
                }
            }
        }
        
        // End observer
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = false
                self?.progress = 1.0
            }
        }
    }
    
    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }
    
    func seek(by seconds: Double) {
        guard let player else { return }
        let current = player.currentTime().seconds
        let target = max(0, current + seconds)
        let time = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func seekToProgress(_ value: Double) {
        guard let player, duration > 0 else { return }
        let target = duration * value
        let time = CMTime(seconds: target, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        progress = value
    }
    
    func stop() {
        player?.pause()
        cleanup()
    }
    
    private func cleanup() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
        }
        statusObserver?.invalidate()
        bufferObserver?.invalidate()
        timeObserver = nil
        statusObserver = nil
        bufferObserver = nil
        player = nil
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
}
