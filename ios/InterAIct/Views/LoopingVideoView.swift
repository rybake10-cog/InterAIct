import AVFoundation
import SwiftUI
import UIKit

/// A muted, control-free video that plays the scenario clip (looping unless Reduce Motion is on).
struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var loops = true
    var onFailure: () -> Void = {}

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.onFailure = onFailure
        view.play(url: url, loops: loops)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.onFailure = onFailure
        view.play(url: url, loops: loops)
    }

    static func dismantleUIView(_ view: PlayerView, coordinator: ()) {
        view.stop()
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }

        private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        private var looper: AVPlayerLooper?
        private var currentURL: URL?
        private var currentLoops: Bool?
        private var statusObservation: NSKeyValueObservation?
        var onFailure: () -> Void = {}

        func play(url: URL, loops: Bool) {
            guard url != currentURL || loops != currentLoops else { return }
            stop()
            currentURL = url
            currentLoops = loops
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            if loops {
                let looper = AVPlayerLooper(player: player, templateItem: item)
                statusObservation = looper.observe(\.status, options: [.initial, .new]) { [weak self] looper, _ in
                    if looper.status == .failed { self?.reportFailure() }
                }
                self.looper = looper
            } else {
                statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
                    if item.status == .failed { self?.reportFailure() }
                }
                player.insert(item, after: nil)
            }
            playerLayer.videoGravity = .resizeAspect
            playerLayer.player = player
            player.play()
        }

        /// Called when the clip can't be decoded (for example HEVC on a simulator without a decoder).
        private nonisolated func reportFailure() {
            DispatchQueue.main.async { [weak self] in
                guard let self, self.playerLayer.player != nil else { return }
                self.stop()
                self.onFailure()
            }
        }

        func stop() {
            statusObservation = nil
            playerLayer.player?.pause()
            looper = nil
            playerLayer.player = nil
            currentURL = nil
            currentLoops = nil
        }
    }
}
