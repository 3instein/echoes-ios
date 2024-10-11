// GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var gameScene: GameScene!
    var playerEntity: PlayerEntity!
    var forwardButton: UIButton!
    var movementTimer: Timer?
    var movementSystem: MovementSystem!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the SCNView
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)
        
        // Set up the GameScene
        gameScene = GameScene()
        scnView.scene = gameScene

        // Set up the PlayerEntity
        playerEntity = gameScene.playerEntity
        
        // Set up the MovementSystem
        movementSystem = MovementSystem(componentClass: MovementComponent.self)
        if let movementComponent = playerEntity.movementComponent {
            movementSystem.addComponent(movementComponent)
        }
        
        // Configure the SCNView
        scnView.allowsCameraControl = false // Disabling manual camera control for testing the movement
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black

        // Create and set up the forward button
        forwardButton = UIButton(type: .system)
        forwardButton.setTitle("Move Forward", for: .normal)
        forwardButton.backgroundColor = UIColor.systemBlue
        forwardButton.setTitleColor(.white, for: .normal)
        forwardButton.layer.cornerRadius = 10
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add target actions for button press and release
        forwardButton.addTarget(self, action: #selector(startMovingForward), for: .touchDown)
        forwardButton.addTarget(self, action: #selector(stopMovingForward), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        self.view.addSubview(forwardButton)
        
        // Set button constraints
        NSLayoutConstraint.activate([
            forwardButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            forwardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50),
            forwardButton.widthAnchor.constraint(equalToConstant: 150),
            forwardButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc func startMovingForward() {
        // Start a timer to update the movement system smoothly
        movementTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(updateMovementSystem), userInfo: nil, repeats: true)
    }
    
    @objc func stopMovingForward() {
        // Invalidate the movement timer to stop moving the player
        movementTimer?.invalidate()
        movementTimer = nil
    }
    
    @objc func updateMovementSystem() {
        // Update the movement system
        movementSystem.updateMovement(deltaTime: 0.02)
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
