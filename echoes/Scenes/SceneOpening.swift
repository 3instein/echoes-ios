//
//  SceneOpening.swift
//  echoes
//
//  Created by Elyora Dior on 16/10/24.
//

import UIKit
import AVKit

class SceneOpening: UIViewController {

    var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load and play video
        if let videoURL = Bundle.main.url(forResource: "scene 1_voice over", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.showsPlaybackControls = false
            
            // Present the player view controller
            self.addChild(playerViewController)
            self.view.addSubview(playerViewController.view)
            playerViewController.view.frame = self.view.bounds
            playerViewController.didMove(toParent: self)

            // Play video
            player?.play()

            // Add observer for when the video finishes playing
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        } else {
            print("Video file not found.")
        }
    }

    @objc func videoDidFinishPlaying() {
        print("Video finished playing")

        // Remove observer
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        // Transition to GameViewController (Scene 1)
        let gameVC = GameViewController()
        gameVC.modalPresentationStyle = .fullScreen
        self.present(gameVC, animated: false) {
            print("GameViewController (Scene 1) presented")
        }
    }
}
