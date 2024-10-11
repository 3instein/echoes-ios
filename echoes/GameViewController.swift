// GameViewController.swift

import UIKit
import SceneKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var gameScene: GameScene!
    var playerEntity: PlayerEntity!
    var forwardButton: UIButton!
    var movementTimer: Timer?

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
        // Start a timer to move the player forward smoothly
        movementTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(movePlayerForward), userInfo: nil, repeats: true)
    }
    
    @objc func stopMovingForward() {
        // Invalidate the movement timer to stop moving the player
        movementTimer?.invalidate()
        movementTimer = nil
    }
    
    @objc func movePlayerForward() {
        // Move the player forward in the direction it is currently facing
        if let playerNode = playerEntity.playerNode {
            let moveVector = SCNVector3(x: 0, y: 0, z: 0.5) // Move in the negative z direction for smooth movement
            let transformedMoveVector = playerNode.simdTransform * simd_float4(moveVector.x, moveVector.y, moveVector.z, 0)
            playerNode.position = SCNVector3(
                x: playerNode.position.x + transformedMoveVector.x,
                y: playerNode.position.y + transformedMoveVector.y,
                z: playerNode.position.z + transformedMoveVector.z
            )
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
