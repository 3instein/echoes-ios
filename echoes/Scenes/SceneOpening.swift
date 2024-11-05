import UIKit
import AVKit
import SceneKit

class SceneOpening: UIViewController {
    
    var player: AVPlayer?
    var skipButton: UIButton?
    var scene2AssetsPrepared = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prepare Scene 2 assets
        prepareScene2Assets()
        
        // Load and play the opening video
        if let videoURL = Bundle.main.url(forResource: "Scene 1", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.showsPlaybackControls = false
            playerViewController.videoGravity = .resizeAspectFill
            
            self.addChild(playerViewController)
            self.view.addSubview(playerViewController.view)
            playerViewController.view.frame = self.view.bounds
            playerViewController.didMove(toParent: self)
            
            player?.play()
            
            // Observer for when the video finishes playing
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
            
        } else {
            print("Video file not found.")
        }
    }
    
    private func prepareScene2Assets() {
        guard let scene2 = SCNScene(named: "scene2.scn") else {
            print("Scene 2 file not found.")
            return
        }
        
        // List nodes or elements to prepare
        let nodesToPrepare = scene2.rootNode.childNodes
        
        // Prepare assets in the background
        let scnView = SCNView()
        scnView.prepare(nodesToPrepare, completionHandler: { [weak self] success in
            self?.scene2AssetsPrepared = success
            if success {
                print("Scene 2 assets successfully prepared.")
                // Show the skip button once assets are ready
                self?.showSkipButton()
            } else {
                print("Failed to prepare Scene 2 assets.")
            }
        })
    }
    
    @objc func videoDidFinishPlaying() {
        print("Video finished playing")
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // Check if Scene 2 assets are fully loaded
        if scene2AssetsPrepared {
            transitionToGameViewController()
        } else {
            // If assets aren't prepared yet, delay and retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.transitionToGameViewController()
            }
        }
    }
    
    private func transitionToGameViewController() {
        let gameVC = GameViewController()
        gameVC.modalPresentationStyle = .fullScreen
        self.present(gameVC, animated: false) {
            print("GameViewController (Scene 1) presented")
        }
    }
    
    func showSkipButton() {
        if skipButton == nil {
            skipButton = UIButton(type: .system)
            skipButton?.setTitle("Skip", for: .normal)
            skipButton?.backgroundColor = UIColor.black.withAlphaComponent(0.4)
            skipButton?.setTitleColor(.white, for: .normal)
            skipButton?.layer.cornerRadius = 5
            
            if let customFont = UIFont(name: "MetalMania-Regular", size: 18) {
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
