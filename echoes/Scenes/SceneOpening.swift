//  SceneOpening.swift

import UIKit
import AVKit
import SceneKit

class SceneOpening: UIViewController {
    // MARK: - Properties & Initialization
    var player: AVPlayer?
    var skipButton: UIButton?
    var scene2AssetsPrepared = false
    var scene4AssetsPrepared = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load and play the opening video
        playOpeningVideo()
        
        // Prepare Scene 2 assets
        prepareScene2Assets()
    }
    
    // MARK: - Video Playback
    private func playOpeningVideo() {
        if let videoURL = Bundle.main.url(forResource: "Scene 1", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.showsPlaybackControls = false
            playerViewController.videoGravity = .resizeAspectFill
            
            // Add video player to the view hierarchy
            self.addChild(playerViewController)
            self.view.addSubview(playerViewController.view)
            playerViewController.view.frame = self.view.bounds
            playerViewController.didMove(toParent: self)
            
            player?.play()
            
            // Observe when the video finishes playing
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem
            )
        } else {
            print("Error: Opening video file not found.")
        }
    }
    
    @objc private func videoDidFinishPlaying() {
        print("Opening video finished.")
        NotificationCenter.default.removeObserver(
            self,
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        // Transition if assets are ready
        if scene2AssetsPrepared {
            transitionToGameViewController()
        } else {
            // Retry after a short delay if assets aren't ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transitionToGameViewController()
            }
        }
    }
    
    // MARK: - Asset Preparation
    private func prepareScene2Assets() {
        AssetPreloader.preloadScene2 { [weak self] success in
            if success {
                print("Scene 2 assets successfully prepared.")
                self?.scene2AssetsPrepared = true
                self?.showSkipButton()
            } else {
                print("Error: Failed to prepare Scene 2 assets.")
                self?.scene2AssetsPrepared = false
            }
        }
    }
    
    // MARK: - Scene Transition
    private func transitionToGameViewController() {
        let gameVC = GameViewController()
        gameVC.modalPresentationStyle = .fullScreen
        self.present(gameVC, animated: false) {
            print("GameViewController (Scene 1) presented.")
        }
    }
    
    // MARK: - Skip Button
    func showSkipButton() {
        guard skipButton == nil else { return }
        
        // Configure skip button
        skipButton = UIButton(type: .system)
        skipButton?.setTitle("Skip", for: .normal)
        skipButton?.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        skipButton?.setTitleColor(.white, for: .normal)
        skipButton?.layer.cornerRadius = 5
        
        if let customFont = UIFont(name: "MetalMania-Regular", size: 18) {
            skipButton?.titleLabel?.font = customFont
        } else {
            print("Warning: Failed to load MetalMania-Regular font.")
        }
        
        if let button = skipButton {
            // Adjust button size and position
            let buttonWidth: CGFloat = 60
            let buttonHeight: CGFloat = 30
            button.frame = CGRect(
                x: self.view.bounds.width - buttonWidth - 20,
                y: 20,
                width: buttonWidth,
                height: buttonHeight
            )
            self.view.addSubview(button)
            button.addTarget(self, action: #selector(skipVideo), for: .touchUpInside)
        }
    }
    
    @objc private func skipVideo() {
        print("User skipped the opening video.")
        
        // Pause and release the player
        player?.pause()
        player = nil
        
        // Remove skip button
        skipButton?.removeFromSuperview()
        skipButton = nil
        
        // Proceed as if the video finished
        videoDidFinishPlaying()
    }
    
    // MARK: - Orientation Configuration
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
}
