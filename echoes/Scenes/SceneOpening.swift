//  SceneOpening.swift

import UIKit
import AVKit

class SceneOpening: UIViewController {
    
    var player: AVPlayer?
    var skipButton: UIButton?
    
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
            
            // Add double tap gesture to show skip button
            let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(showSkipButton))
            doubleTapGesture.numberOfTapsRequired = 2
            self.view.addGestureRecognizer(doubleTapGesture)
            
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
    
    @objc func showSkipButton() {
        if skipButton == nil {
            skipButton = UIButton(type: .system)
            skipButton?.setTitle("Skip", for: .normal)
            skipButton?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            skipButton?.setTitleColor(.white, for: .normal)
            skipButton?.layer.cornerRadius = 5
            
            if let customFont = UIFont(name: "MetalMania-Regular", size: 20) {
                skipButton?.titleLabel?.font = customFont
            } else {
                print("Failed to load MetalMania-Regular font.")
            }
            
            if let button = skipButton {
                let buttonWidth: CGFloat = 60
                let buttonHeight: CGFloat = 30
                button.frame = CGRect(x: self.view.bounds.width - buttonWidth - 20, y: 20, width: buttonWidth, height: buttonHeight)
                self.view.addSubview(button)
            }
            
            skipButton?.addTarget(self, action: #selector(skipVideo), for: .touchUpInside)
        }
    }
    
    @objc func skipVideo() {
        print("Video skipped by user")
        
        // Pause and clean up the player
        player?.pause()
        
        // Optionally release the player
        player = nil
        
        // Remove skip button from view
        skipButton?.removeFromSuperview()
        skipButton = nil
        
        // Call the same function when the video finishes
        videoDidFinishPlaying()
    }
}
