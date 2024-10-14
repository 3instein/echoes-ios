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
        SceneManager.shared.loadScene1()

        // Set up the PlayerEntity
        if let gameScene = scnView.scene as? Scene1 {
            playerEntity = PlayerEntity(in: gameScene.rootNode, cameraNode: gameScene.cameraNode)
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

        // Set up the camera gesture recognizers
        if let gameScene = scnView.scene as? Scene1 {
            gameScene.setupGestureRecognizers(for: scnView)
        }

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
