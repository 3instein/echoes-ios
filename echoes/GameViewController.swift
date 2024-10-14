// GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController {
    var scnView: SCNView!
    var playerEntity: PlayerEntity!
    var joystickComponent: VirtualJoystickComponent!
    var audioSource: SCNAudioSource!
    let scene = SCNScene(named: "art.scnassets/musicbox.scn")!
    
    lazy var musicBoxNode = scene.rootNode.childNode(withName: "musicbox", recursively: true)!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the SCNView
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)
        
        // Configure SceneManager with the SCNView
        SceneManager.shared.configure(with: scnView)
        
        // Use SceneManager to load Scene1
        SceneManager.shared.loadScene1()
        
        // Set up the PlayerEntity from the loaded Scene1
        if let scene1 = scnView.scene as? Scene1 {
            playerEntity = scene1.playerEntity
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
