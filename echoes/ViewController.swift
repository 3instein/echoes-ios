import UIKit
import AVKit // Import AVKit for video playback

class ViewController: UIViewController {

    var titleLabel: UILabel!
    var mainMenuImageView: UIImageView!
    var playButton: UIButton!
    var settingsButton: UIButton!
    var creditsButton: UIButton!
    var player: AVPlayer?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the image view
        mainMenuImageView = UIImageView()
        mainMenuImageView.contentMode = .scaleAspectFill
        mainMenuImageView.image = UIImage(named: "MainMenu")
        mainMenuImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainMenuImageView)
        
        // Auto Layout for the image view
        NSLayoutConstraint.activate([
            mainMenuImageView.topAnchor.constraint(equalTo: view.topAnchor),
            mainMenuImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainMenuImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainMenuImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Create the title label
        titleLabel = UILabel()
        titleLabel.text = "ECHOES"
        
        // Apply the custom MetalMania-Regular font
        if let customFont = UIFont(name: "MetalMania-Regular", size: 110) {
            titleLabel.font = customFont
        } else {
            print("Failed to load MetalMania-Regular font.")
        }
        
        // Customize appearance
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the title label to the view
        view.addSubview(titleLabel)
        
        // Auto Layout for the title label
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 70)
        ])
        
        // Create and style the buttons
        playButton = createButton(withText: "Play")
        settingsButton = createButton(withText: "Settings")
        creditsButton = createButton(withText: "Credits")
        
        // Add action to the play button
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        // Add buttons to the view
        view.addSubview(playButton)
        view.addSubview(settingsButton)
        view.addSubview(creditsButton)
        
        // Auto Layout for the buttons
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),
            
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 10),
            
            creditsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            creditsButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 10)
        ])
    }

    func createButton(withText text: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        
        // Load and apply the custom font for buttons
        if let customFont = UIFont(name: "SpecialElite-Regular", size: 28) {
            button.titleLabel?.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
        
        // Customize appearance
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }

    @objc func playButtonTapped() {
        if let videoURL = Bundle.main.url(forResource: "scene 1_voice over", withExtension: "mp4") {
            player = AVPlayer(url: videoURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.showsPlaybackControls = false // Hide playback controls

            present(playerViewController, animated: true) {
                self.player?.play() // Play video automatically
            }

            // Ensure the observer is properly set for the player's current item
            NotificationCenter.default.addObserver(self, selector: #selector(videoDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        } else {
            print("Video file not found.")
        }
    }

    @objc func videoDidFinishPlaying() {
        print("Video finished playing")

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        // Dismiss the AVPlayerViewController before presenting GameViewController
        dismiss(animated: false) {
            // Transition to Scene 1 (GameViewController)
            let gameVC = GameViewController()
            gameVC.modalPresentationStyle = .fullScreen
            self.present(gameVC, animated: false, completion: {
                print("GameViewController presented")
            })
        }
    }




    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
