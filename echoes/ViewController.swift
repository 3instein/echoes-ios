import UIKit

class ViewController: UIViewController {
    
    var mainMenuImageView: UIImageView!
    var playButton: UIButton!
    var settingsButton: UIButton!
    var creditsButton: UIButton!
    
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
        
        // Create and style the buttons
        playButton = createButton(withText: "Play")
//        settingsButton = createButton(withText: "Settings")
//        creditsButton = createButton(withText: "Credits")
        
        // Add buttons to the view
        view.addSubview(playButton)
//        view.addSubview(settingsButton)
//        view.addSubview(creditsButton)
        
        // Auto Layout for the buttons
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            
//            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            settingsButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
//            
//            creditsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            creditsButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 20)
        ])
    }
    
    func createButton(withText text: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(text, for: .normal)
        
        // Customize font and appearance
        button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 28) // Choose a font that suits your design
        button.setTitleColor(.white, for: .normal)
        
        // Add a background color to highlight the button, like in your image
        button.backgroundColor = UIColor(white: 1.0, alpha: 0.1) // Light transparency effect
        button.layer.cornerRadius = 10
        
        // Add shadow effect
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.layer.shadowOpacity = 0.8
        button.layer.shadowRadius = 4
        
        // Enable Auto Layout
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
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
