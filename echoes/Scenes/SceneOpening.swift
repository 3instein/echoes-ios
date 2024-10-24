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
        if let videoURL = Bundle.main.url(forResource: "Scene 1", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.showsPlaybackControls = false
            playerViewController.videoGravity = .resizeAspectFill
            
            // Present the player view controller
            self.addChild(playerViewController)
            self.view.addSubview(playerViewController.view)
            playerViewController.view.frame = self.view.bounds
            playerViewController.didMove(toParent: self)

            // Play video
            player?.play()

            // Add observer for when the video finishes playing
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            
            // Add tap gesture to skip video
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(skipVideo))
            self.view.addGestureRecognizer(tapGesture)

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
    
    @objc func skipVideo() {
        print("Video skipped by user")
        
        // Pause and clean up the player
        player?.pause()
        player = nil // Optionally release the player

        // Call the same function when the video finishes
        videoDidFinishPlaying()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }
}
