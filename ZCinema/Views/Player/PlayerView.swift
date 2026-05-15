import SwiftUI
import AVKit
import WebKit

// MARK: - PlayerView
struct PlayerView: View {
    let stream: ResolvedStream
    @ObservedObject var detailVM: DetailViewModel

    @Environment(\.dismiss) private var dismiss
    @StateObject private var pvm = PlayerViewModel()

    @State private var controlsVisible = true
    @State private var hideTask: Task<Void, Never>? = nil
    @State private var showEpisodes = false
    @State private var isDraggingSeek = false
    @State private var dragProgress: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // ── Video layer ───────────────────────────────────────
            videoLayer

            // ── Buffering spinner ─────────────────────────────────
            if pvm.isBuffering && !pvm.isPlaying {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.6)
            }

            // ── Error ─────────────────────────────────────────────
            if let err = pvm.errorMessage {
                errorOverlay(err)
            }

            // ── Controls ──────────────────────────────────────────
            if controlsVisible {
                controlsLayer
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
            }

            // ── Episode side panel ────────────────────────────────
            if showEpisodes {
                episodePanel
                    .transition(.move(edge: .trailing).animation(.spring(response: 0.3)))
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .onTapGesture { toggleControls() }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            pvm.load(stream)
            scheduleHide()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            pvm.stop()
            hideTask?.cancel()
        }
        .onChange(of: detailVM.resolvedStream) { newStream in
            guard let s = newStream else { return }
            pvm.load(s)
        }
    }

    // MARK: - Video layer
    @ViewBuilder
    private var videoLayer: some View {
        if stream.kind == .iframe {
            IframePlayer(url: stream.url)
                .ignoresSafeArea()
        } else {
            NativePlayer(player: pvm.player)
                .ignoresSafeArea()
        }
    }

    // MARK: - Controls layer
    private var controlsLayer: some View {
        ZStack {
            // Top gradient
            VStack {
                LinearGradient(colors: [.black.opacity(0.72), .clear],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 110)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.82)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 130)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer()
                centerControls
                Spacer()
                bottomBar
            }
        }
    }

    // MARK: - Top bar
    private var topBar: some View {
        HStack(spacing: 14) {
            // Back
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 2) {
                if let item = detailVM.detail {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                if let ep = detailVM.selectedEpisode {
                    Text("الحلقة \(ep.number)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.7))
                }
            }

            Spacer()

            // Quality badge
            Text(stream.quality)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(red: 0.9, green: 0.1, blue: 0.1).opacity(0.9))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            // Episode list (series only)
            if detailVM.detail?.type != .movie {
                Button {
                    withAnimation { showEpisodes.toggle() }
                    scheduleHide()
                } label: {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 52)
    }

    // MARK: - Center controls
    private var centerControls: some View {
        HStack(spacing: 38) {
            // Previous episode
            if detailVM.detail?.type != .movie {
                Button {
                    detailVM.goPrev()
                    scheduleHide()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 24))
                        .foregroundColor(detailVM.canGoPrev ? .white : .white.opacity(0.3))
                }
                .disabled(!detailVM.canGoPrev)
            }

            // Seek -10
            Button {
                pvm.seek(by: -10)
                scheduleHide()
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            // Play / Pause
            Button {
                pvm.togglePlay()
                scheduleHide()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 66, height: 66)

                    if pvm.isBuffering {
                        ProgressView().tint(.white).scaleEffect(1.1)
                    } else {
                        Image(systemName: pvm.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                            .offset(x: pvm.isPlaying ? 0 : 2)
                    }
                }
            }

            // Seek +10
            Button {
                pvm.seek(by: 10)
                scheduleHide()
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            // Next episode
            if detailVM.detail?.type != .movie {
                Button {
                    detailVM.goNext()
                    scheduleHide()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 24))
                        .foregroundColor(detailVM.canGoNext ? .white : .white.opacity(0.3))
                }
                .disabled(!detailVM.canGoNext)
            }
        }
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        VStack(spacing: 8) {
            // Progress bar
            SeekBar(
                progress:   Binding(
                    get: { isDraggingSeek ? dragProgress : pvm.progress },
                    set: { _ in }
                ),
                buffered:   pvm.buffered,
                onDragStart: {
                    isDraggingSeek = true
                    dragProgress = pvm.progress
                    hideTask?.cancel()
                },
                onDrag: { v in dragProgress = v },
                onDragEnd: { v in
                    pvm.seekToFraction(v)
                    isDraggingSeek = false
                    scheduleHide()
                }
            )
            .padding(.horizontal, 18)

            // Time labels
            HStack {
                Text(formatTime(pvm.currentTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.75))
                Spacer()
                Text(formatTime(pvm.duration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.75))
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 44)
    }

    // MARK: - Episode panel
    private var episodePanel: some View {
        HStack(spacing: 0) {
            // Tap outside to close
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { showEpisodes = false }
                }

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("الحلقات")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        withAnimation { showEpisodes = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.55))
                            .padding(8)
                            .background(Color(white: 0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(14)
                .background(Color(white: 0.10))

                Divider().background(Color(white: 0.2))

                // Episodes
                if let season = detailVM.selectedSeason {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(season.episodes) { ep in
                                PanelEpRow(
                                    ep: ep,
                                    isCurrent: detailVM.selectedEpisode?.id == ep.id
                                ) {
                                    detailVM.selectEpisode(ep)
                                    withAnimation { showEpisodes = false }
                                }
                                Divider().background(Color(white: 0.14))
                            }
                        }
                    }
                }
            }
            .frame(width: min(UIScreen.main.bounds.width * 0.42, 290))
            .background(Color(white: 0.08))
            .ignoresSafeArea()
        }
    }

    // MARK: - Error overlay
    private func errorOverlay(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
            Text("خطأ في التشغيل")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Helpers
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) {
            controlsVisible.toggle()
        }
        if controlsVisible { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    controlsVisible = false
                }
            }
        }
    }

    private func formatTime(_ s: Double) -> String {
        guard s.isFinite, s >= 0 else { return "0:00" }
        let t = Int(s)
        let h = t / 3600, m = (t % 3600) / 60, sec = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, sec)
            : String(format: "%d:%02d", m, sec)
    }
}

// MARK: - SeekBar
struct SeekBar: View {
    @Binding var progress: Double
    let buffered: Double
    let onDragStart: () -> Void
    let onDrag: (Double) -> Void
    let onDragEnd: (Double) -> Void

    @State private var dragging = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack(alignment: .leading) {
                // Track
                Capsule().fill(Color.white.opacity(0.22))
                    .frame(height: dragging ? 5 : 3)

                // Buffered
                Capsule().fill(Color.white.opacity(0.38))
                    .frame(width: max(0, min(w, w * buffered)), height: dragging ? 5 : 3)

                // Progress
                Capsule().fill(Color(red: 0.9, green: 0.1, blue: 0.1))
                    .frame(width: max(0, min(w, w * progress)), height: dragging ? 5 : 3)

                // Thumb
                Circle()
                    .fill(.white)
                    .shadow(radius: 3)
                    .frame(width: dragging ? 18 : 13, height: dragging ? 18 : 13)
                    .offset(x: max(0, min(w - (dragging ? 18 : 13),
                                          w * progress - (dragging ? 9 : 6.5))))
                    .animation(.easeInOut(duration: 0.1), value: dragging)
            }
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        if !dragging { dragging = true; onDragStart() }
                        let v = max(0, min(1, val.location.x / w))
                        onDrag(v)
                    }
                    .onEnded { val in
                        let v = max(0, min(1, val.location.x / w))
                        dragging = false
                        onDragEnd(v)
                    }
            )
        }
        .frame(height: 22)
    }
}

// MARK: - Panel episode row
struct PanelEpRow: View {
    let ep: Episode
    let isCurrent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isCurrent
                              ? Color(red: 0.9, green: 0.1, blue: 0.1)
                              : Color(white: 0.22))
                        .frame(width: 34, height: 34)
                    Text("\(ep.number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                Text(ep.title)
                    .font(.system(size: 13))
                    .foregroundColor(isCurrent ? .white : Color(white: 0.72))
                Spacer()
                if isCurrent {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 11)
            .background(isCurrent ? Color.white.opacity(0.07) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Native AVPlayer UIViewControllerRepresentable
struct NativePlayer: UIViewControllerRepresentable {
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

// MARK: - Iframe WKWebView player
struct IframePlayer: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.backgroundColor = .black
        wv.scrollView.isScrollEnabled = false
        wv.scrollView.bounces = false
        load(into: wv)
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        if wv.url?.absoluteString != url { load(into: wv) }
    }

    private func load(into wv: WKWebView) {
        guard let u = URL(string: url) else { return }
        var req = URLRequest(url: u)
        req.setValue("https://egibest.ws/", forHTTPHeaderField: "Referer")
        wv.load(req)
    }
}
