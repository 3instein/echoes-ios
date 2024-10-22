// GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var playerEntity: PlayerEntity!
    var joystickComponent: VirtualJoystickComponent!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the SCNView
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)

        // Configure the SceneManager with the SCNView
        SceneManager.shared.configure(with: scnView)

        // Load the initial game scene
        SceneManager.shared.loadScene5()
        
        // Set up joystick component
        joystickComponent = VirtualJoystickComponent()
        joystickComponent.attachToView(self.view)

        // Set up the PlayerEntity
        if let gameScene = scnView.scene as? Scene5 {
            playerEntity = gameScene.playerEntity
            
            // Create a movement component to handle player movement, including the light node
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
            playerEntity.movementComponent = movementComponent
            
            // Link the joystick with the movement component
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = joystickComponent
            }
            
            // Set up fog properties for the scene
//            gameScene.fogStartDistance = 50.0   // Increase the start distance
//            gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
//            gameScene.fogDensityExponent = 0.2  // Reduce density to make the fog less thick
//            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: scnView)
        }
        
        //playerEntity.movementComponent.movePlayer(to: SCNVector3(-15.538, -29.942, 0.728), duration: 20.0)

        // Configure the SCNView
        scnView.allowsCameraControl = false
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black

        // Start the update loop
        let displayLink = CADisplayLink(target: self, selector: #selector(updateScene))
        displayLink.add(to: .main, forMode: .default)
    }

    @objc func updateScene() {
        playerEntity?.movementComponent?.update(deltaTime: 0.016)
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
