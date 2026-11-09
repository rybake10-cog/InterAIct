import AVFoundation
import SwiftUI
import UIKit

/// A muted, control-free video that plays the scenario clip (looping unless Reduce Motion is on).
struct LoopingVideoView: UIViewRepresentable {
    let url: URL
    var loops = true

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.play(url: url, loops: loops)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
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

        func play(url: URL, loops: Bool) {
            guard url != currentURL || loops != currentLoops else { return }
            stop()
            currentURL = url
            currentLoops = loops
            let item = AVPlayerItem(url: url)
            let player = AVQueuePlayer()
            player.isMuted = true
            if loops {
                looper = AVPlayerLooper(player: player, templateItem: item)
            } else {
                player.insert(item, after: nil)
            }
            playerLayer.videoGravity = .resizeAspect
            playerLayer.player = player
            player.play()
        }

        func stop() {
            playerLayer.player?.pause()
            looper = nil
            playerLayer.player = nil
            currentURL = nil
            currentLoops = nil
        }
    }
}
