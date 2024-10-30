//  GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController, Scene2Delegate {
    static var shared = GameViewController()
    var scnView: SCNView!
    static var playerEntity: PlayerEntity!
    static var joystickComponent: VirtualJoystickComponent!
    var scene6: Scene6!
    
    var interactButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the SCNView
        scnView = SCNView(frame: self.view.frame)
        self.view.addSubview(scnView)
        
        // Configure the SceneManager with the SCNView
        SceneManager.shared.configure(with: scnView)
        
        // Set up joystick component
        GameViewController.joystickComponent = VirtualJoystickComponent.shared
        GameViewController.joystickComponent.attachToView(self.view)
        
        // Load the initial game scene
        SceneManager.shared.loadScene2()
        
        // Set up the PlayerEntity for Scene2
        if let gameScene = self.scnView.scene as? Scene2 {
            GameViewController.playerEntity = gameScene.playerEntity
            gameScene.delegate = self // Set delegate to handle Scene2 transition
            
            // Create a movement component to handle player movement, including the light node
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode)
            GameViewController.playerEntity.movementComponent = movementComponent
            
            GameViewController.joystickComponent.hideJoystick()
            
            // Link the joystick with the movement component
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                scnView.scene?.physicsWorld.contactDelegate = movementComponent
            }
            
            // Set up fog properties for the scene
            gameScene.fogStartDistance = 25.0
            gameScene.fogEndDistance = 300.0
            gameScene.fogDensityExponent = 0.2
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
            
            // Start the walking sequence and cutscene in Scene2
            gameScene.startWalkingToHouse()
        }
        
        // Configure the SCNView
        scnView.allowsCameraControl = false
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
        
        // Create and configure the interaction button
        interactButton = UIButton(type: .system)
        interactButton.setTitle("Play", for: .normal)
        if let customFont = UIFont(name: "SpecialElite-Regular", size: 16) {
            interactButton.titleLabel?.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
        interactButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        interactButton.setTitleColor(.blue, for: .normal)
        interactButton.layer.cornerRadius = 15
        interactButton.frame = CGRect(x: 100, y: 100, width: 100, height: 30)
        interactButton.isHidden = true
        interactButton.addTarget(self, action: #selector(interactWithCake), for: .touchUpInside)
        self.view.addSubview(interactButton)
        
        // Start the update loop
        let displayLink = CADisplayLink(target: self, selector: #selector(updateScene))
        displayLink.add(to: .main, forMode: .default)
    }
    
    func transitionToScene4() {
        // Load Scene4 after Scene2 finishes
        SceneManager.shared.loadScene4()
        
        if let gameScene = self.scnView.scene as? Scene4 {
            GameViewController.playerEntity = gameScene.playerEntity
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode)
            GameViewController.playerEntity.movementComponent = movementComponent
            
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                self.scnView.scene?.physicsWorld.contactDelegate = movementComponent
            }
            
            gameScene.fogStartDistance = 25.0
            gameScene.fogEndDistance = 300.0
            gameScene.fogDensityExponent = 0.2
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
        }
    }
    
    @objc func updateScene() {
        GameViewController.playerEntity?.movementComponent?.update(deltaTime: 0.016)
        
        if let gameScene = scnView.scene as? Scene4 {
            // Check if the player is near the transition point
            if gameScene.checkProximityToTransition() {
                // Load Scene3 after the movement finishes
                SceneManager.shared.loadScene5()
                
                if let gameScene = self.scnView.scene as? Scene5 {
                    GameViewController.playerEntity = gameScene.playerEntity
                    
                    // Create a movement component to handle player movement, including the light node
                    let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
                    GameViewController.playerEntity.movementComponent = movementComponent
                    
                    // GameViewController.playerEntity.movementComponent?.resetMovementAndLight()
                    
                    // Link the joystick with the movement component
                    if let movementComponent = gameScene.playerEntity.movementComponent {
                        movementComponent.joystickComponent = GameViewController.joystickComponent
                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
                    }
                    
                    // Set up fog properties for the scene
                    gameScene.fogStartDistance = 25.0   // Increase the start distance
                    gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
                    gameScene.fogDensityExponent = 0.3  // Reduce density to make the fog less thick
                    gameScene.fogColor = UIColor.black
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                }
            }
        }
        
        if let gameScene = scnView.scene as? Scene5 {
            // Check if the player is near the transition point
            if gameScene.checkProximityToTransition() {
                // Load Scene6 after the movement finishes
                SceneManager.shared.loadScene6()
                
                if let gameScene = self.scnView.scene as? Scene6 {
                    GameViewController.playerEntity = gameScene.playerEntity
                    
                    // Create a movement component to handle player movement, including the light node
                    let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
                    GameViewController.playerEntity.movementComponent = movementComponent
                    
                    // Link the joystick with the movement component
                    if let movementComponent = gameScene.playerEntity.movementComponent {
                        movementComponent.joystickComponent = GameViewController.joystickComponent
                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
                    }
                    
                    // Set up fog properties for the scene
                    gameScene.fogStartDistance = 25.0   // Increase the start distance
                    gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
                    gameScene.fogDensityExponent = 0.5  // Reduce density to make the fog less thick
                    gameScene.fogColor = UIColor.black
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                }
            }
        }
        // Check proximity to the cake
        if let gameScene = scnView.scene as? Scene6 {
            gameScene.checkProximityToCake(interactButton: interactButton)  // Pass the button to the check
            if gameScene.isPuzzleDisplayed {
                GameViewController.joystickComponent.joystickView.isHidden = true
            } else {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
        }
    }
    
    @objc func interactWithCake() {
        // Now check if the loaded scene is Scene1 and assign it to the scene1 variable
        if let loadedScene = scnView.scene as? Scene6 {
            scene6 = loadedScene
        } else {
            print("Error: Scene1 not loaded correctly")
        }
        if let gameScene = scene6 {
            gameScene.displayPuzzlePieces(on: self.view)
            gameScene.addOpenFridgeSound()
        } else {
            print("Error: Scene6 is not initialized.")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update the frame of scnView
        scnView.frame = self.view.bounds
        
        // Update joystick position
        GameViewController.joystickComponent.joystickView.frame = CGRect(
            x: 50,
            y: self.view.bounds.height - GameViewController.joystickComponent.joystickSize - 50,
            width: GameViewController.joystickComponent.joystickSize,
            height: GameViewController.joystickComponent.joystickSize
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GameViewController.joystickComponent.joystickView.removeFromSuperview()
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
