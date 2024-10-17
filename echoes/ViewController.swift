import UIKit
import AVFoundation // Import AVFoundation for audio playback

class ViewController: UIViewController {
    
    var titleLabel: UILabel!
    var mainMenuImageView: UIImageView!
    var playButton: UIButton!
    var settingsButton: UIButton!
    var creditsButton: UIButton!
    var audioPlayer: AVAudioPlayer? // Add AVAudioPlayer property
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playBackgroundMusic() // Call function to play the soundtrack

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
            // Add margin to the top of the first button
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40), // Increase this constant to add margin from the center
            
            // Reduce gap between the buttons
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 10), // Reduce this constant for a smaller gap
            
            creditsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            creditsButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 10) // Reduce this constant for a smaller gap
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
    
    func playBackgroundMusic() {
        if let musicURL = Bundle.main.url(forResource: "Soundtrack", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: musicURL)
                audioPlayer?.numberOfLoops = -1 // Loop the audio indefinitely
                audioPlayer?.play()
            } catch {
                print("Failed to load and play the soundtrack: \(error)")
            }
        } else {
            print("Soundtrack.mp3 file not found.")
        }
    }
    
    @objc func playButtonTapped() {
        audioPlayer?.stop()

        // Navigate to SceneOpening to show the video
        let sceneOpeningVC = SceneOpening()
        sceneOpeningVC.modalPresentationStyle = .fullScreen
        self.present(sceneOpeningVC, animated: true) {
            print("SceneOpening presented")
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
