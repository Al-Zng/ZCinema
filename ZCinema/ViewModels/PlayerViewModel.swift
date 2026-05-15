import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var isPlaying  = false
    @Published var isBuffering = true
    @Published var progress   : Double = 0      // 0–1
    @Published var buffered   : Double = 0      // 0–1
    @Published var currentTime: Double = 0      // seconds
    @Published var duration   : Double = 0      // seconds
    @Published var errorMessage: String? = nil

    private(set) var player: AVPlayer? = nil
    private var timeObserver: Any? = nil
    private var itemObservers: [NSKeyValueObservation] = []
    private var endObserver: NSObjectProtocol? = nil

    // ─── Load a resolved stream ───────────────────────────────────
    func load(_ stream: ResolvedStream) {
        cleanup()
        guard let url = URL(string: stream.url) else {
            errorMessage = "رابط تشغيل غير صحيح"
            return
        }

        var headers: [String: String] = [
            "Referer":    "https://egibest.ws/",
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
                        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        ]

        let asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
        let item  = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 10

        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = true
        self.player = p

        // Status
        let statusObs = item.observe(\.status, options: .new) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isBuffering = false
                    self.duration = item.duration.seconds.isNaN ? 0 : item.duration.seconds
                    p.play()
                    self.isPlaying = true
                case .failed:
                    self.errorMessage = item.error?.localizedDescription ?? "خطأ في التشغيل"
                    self.isBuffering  = false
                default: break
                }
            }
        }

        // Buffering
        let bufObs = item.observe(\.isPlaybackLikelyToKeepUp, options: .new) { [weak self] item, _ in
            Task { @MainActor [weak self] in
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp
            }
        }

        itemObservers = [statusObs, bufObs]

        // Time observer (every 0.5 s)
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self, weak p] time in
            guard let self, let p else { return }
            Task { @MainActor [weak self, weak p] in
                guard let self, let p else { return }
                let ct  = time.seconds
                let dur = p.currentItem?.duration.seconds ?? 0
                self.currentTime = ct.isNaN ? 0 : ct
                if dur > 0 && !dur.isNaN {
                    self.duration = dur
                    self.progress = ct / dur
                }
                // Buffered range
                if let range = p.currentItem?.loadedTimeRanges.first {
                    let end = CMTimeRangeGetEnd(range.timeRangeValue).seconds
                    if dur > 0 { self.buffered = end / dur }
                }
            }
        }

        // End of playback
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isPlaying = false
            }
        }
    }

    // ─── Controls ─────────────────────────────────────────────────
    func togglePlay() {
        guard let player else { return }
        if isPlaying { player.pause(); isPlaying = false }
        else         { player.play();  isPlaying = true  }
    }

    func seek(by delta: Double) {
        guard let player else { return }
        let target = max(0, (player.currentTime().seconds) + delta)
        seekTo(seconds: target)
    }

    func seekToFraction(_ fraction: Double) {
        guard duration > 0 else { return }
        seekTo(seconds: duration * max(0, min(1, fraction)))
        progress = fraction
    }

    private func seekTo(seconds: Double) {
        let t = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // ─── Cleanup ──────────────────────────────────────────────────
    func stop() { cleanup() }

    private func cleanup() {
        player?.pause()
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        timeObserver = nil
        itemObservers.forEach { $0.invalidate() }
        itemObservers = []
        if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
        endObserver = nil
        player = nil
        isPlaying   = false
        isBuffering = true
        progress    = 0
        buffered    = 0
        currentTime = 0
        duration    = 0
        errorMessage = nil
    }
}
