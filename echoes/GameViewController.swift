// GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var playerEntity: PlayerEntity!
    var joystickComponent: VirtualJoystickComponent!
    var scene1: Scene1!
    var scene6: Scene6!
    
    var interactButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the SCNView
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)

        // Configure the SceneManager with the SCNView
        SceneManager.shared.configure(with: scnView)

        // Load the initial game scene
        SceneManager.shared.loadScene6()

        // Now check if the loaded scene is Scene1 and assign it to the scene1 variable
        if let loadedScene = scnView.scene as? Scene6 {
            scene6 = loadedScene
//            // Call displayPuzzlePieces after ensuring scene1 is not nil

        } else {
            print("Error: Scene1 not loaded correctly")
        }

        // Set up the PlayerEntity
        if let gameScene = scnView.scene as? Scene6 {
            playerEntity = PlayerEntity(in: gameScene.rootNode, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode)
            
            // Set up fog properties for the scene
            gameScene.fogStartDistance = 50.0   // Increase the start distance
            gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
            gameScene.fogDensityExponent = 0.2  // Reduce density to make the fog less thick
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: scnView)
        }

        // Set up joystick component
        joystickComponent = VirtualJoystickComponent()
        joystickComponent.attachToView(self.view)

        // Link the joystick with the movement component
        if let movementComponent = playerEntity?.movementComponent {
            movementComponent.joystickComponent = joystickComponent
        }
        
        // Configure the SCNView
        scnView.allowsCameraControl = false
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
        
        // Create and configure the interaction button
        interactButton = UIButton(type: .system)
        interactButton.setTitle("Play", for: .normal)
        // Load and apply the custom font for buttons
        if let customFont = UIFont(name: "SpecialElite-Regular", size: 16) {
            interactButton.titleLabel?.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
        interactButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        interactButton.setTitleColor(.blue, for: .normal)
        interactButton.layer.cornerRadius = 15
        interactButton.frame = CGRect(x: 100, y: 100, width: 100, height: 30) // Adjust position and size
        interactButton.isHidden = true // Hide button initially
        interactButton.addTarget(self, action: #selector(interactWithCake), for: .touchUpInside)
        self.view.addSubview(interactButton)
        
        // Start the update loop
        let displayLink = CADisplayLink(target: self, selector: #selector(updateScene))
        displayLink.add(to: .main, forMode: .default)
    }

    @objc func updateScene() {
        playerEntity?.movementComponent?.update(deltaTime: 0.016)
        
        // Check proximity to the cake
        if let gameScene = scnView.scene as? Scene6 {
            gameScene.checkProximityToCake(interactButton: interactButton)  // Pass the button to the check
            if gameScene.isPuzzleDisplayed {
                joystickComponent.joystickView.isHidden = true
            } else {
                joystickComponent.joystickView.isHidden = false
            }
        }
    }

    @objc func interactWithCake() {
        scene6.displayPuzzlePieces(on: self.view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Update the frame of scnView
        scnView.frame = self.view.bounds

        // Update joystick position
        joystickComponent.joystickView.frame = CGRect(
            x: 50,
            y: self.view.bounds.height - joystickComponent.joystickSize - 50,
            width: joystickComponent.joystickSize,
            height: joystickComponent.joystickSize
        )
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        joystickComponent.joystickView.removeFromSuperview()
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
