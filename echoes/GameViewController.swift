//  GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController, Scene2Delegate {
    static var shared = GameViewController()
    static var playerEntity: PlayerEntity!
    static var joystickComponent: VirtualJoystickComponent!
    static var isGrandmaPicked: Bool = false
    static var isRezaPicked: Bool = false
    static var isAyuPicked: Bool = false

    static var isCauseCorrect: Bool = false

    static var previousPlayerChoice: String? = "Ayu" // This can be "Ayu" or "Reza"
    
    var scnView: SCNView!
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
        SceneManager.shared.loadScene11()
        
        // Set up the PlayerEntity for Scene2
        if let gameScene = self.scnView.scene as? Scene11 {
            GameViewController.playerEntity = gameScene.playerEntity
            // Set delegate to handle Scene2 transition
            //            gameScene.delegate = self
            
            // Create a movement component to handle player movement, including the light node
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode)
            GameViewController.playerEntity.movementComponent = movementComponent
            
            //            GameViewController.joystickComponent.hideJoystick()
            
            // Link the joystick with the movement component
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                scnView.scene?.physicsWorld.contactDelegate = movementComponent
            }
            
            // Set up fog properties for the scene
            //            gameScene.fogStartDistance = 100.0
            //            gameScene.fogEndDistance = 300.0
            //            gameScene.fogDensityExponent = 0.2
            //            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
            
            // Start the walking sequence and cutscene in Scene2
            //            gameScene.startWalkingToHouse()
        }
        
        if let gameScene = self.scnView.scene as? Scene11 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) { [weak self] in
                gameScene.showPurpleBackgroundOverlay(in: self!.view!)
            }
        }
        
        // Configure the SCNView
        scnView.allowsCameraControl = false
//        scnView.showsStatistics = true
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            GameViewController.joystickComponent.showJoystick()
        }
        GameViewController.joystickComponent.showJoystickTutorial()
        
        // Temporarily reset the background color to clear (prevents black background flash)
        scnView.backgroundColor = UIColor.clear
        
        if let gameScene = self.scnView.scene as? Scene4 {
            GameViewController.playerEntity = gameScene.playerEntity
            
            // Create a movement component to handle player movement, including the light node
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode)
            GameViewController.playerEntity.movementComponent = movementComponent
            
            // Link the joystick with the movement component
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                self.scnView.scene?.physicsWorld.contactDelegate = movementComponent
            }
            
            // Set up fog properties for the scene
            gameScene.fogStartDistance = 25.0
            gameScene.fogEndDistance = 300.0
            gameScene.fogDensityExponent = 0.2
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
            
            // After scene loads, set the background back to black
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.scnView.backgroundColor = UIColor.black
            }
        }
    }
    
    @objc func updateScene() {
        GameViewController.playerEntity?.movementComponent?.update(deltaTime: 0.016)
        
        if let gameScene = scnView.scene as? Scene4 {
            // Check if the player is near the transition point
            if gameScene.checkProximityToTransition() {
                // Load Scene5 if player is near transition
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
                // Load Scene6 if player is near transition
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
                    gameScene.fogStartDistance = 25.0
                    gameScene.fogEndDistance = 300.0
                    gameScene.fogDensityExponent = 0.5
                    gameScene.fogColor = UIColor.black
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                }
            }
        }
        // Check proximity to the cake in Scene6
        if let gameScene = scnView.scene as? Scene6 {
            gameScene.checkProximityToCake(interactButton: interactButton)
            if gameScene.isPuzzleDisplayed {
                GameViewController.joystickComponent.joystickView.isHidden = true
            } else {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
        }
        
        if let gameScene = scnView.scene as? Scene11 {
            print(gameScene.isDeathPicked)
            if gameScene.isDeathPicked {
                // Load Scene6 if player is near transition
                SceneManager.shared.loadScene12()
                
                if let gameScene = self.scnView.scene as? Scene12 {
                    GameViewController.playerEntity = gameScene.playerEntity

                    // Create a movement component to handle player movement, including the light node
                    let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
                    GameViewController.playerEntity.movementComponent = movementComponent
                    
                    // Link the joystick with the movement component
                    if let movementComponent = gameScene.playerEntity.movementComponent {
                        movementComponent.joystickComponent = GameViewController.joystickComponent
                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
                    }
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                    
                    if (GameViewController.isGrandmaPicked && GameViewController.isCauseCorrect) ||
                        GameViewController.isAyuPicked || GameViewController.isRezaPicked {                        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) { [weak self] in
                            gameScene.setupAndStartSlideshow(on: self!.view!)
                        }
                    }
                }
            }
        }
        
        if let gameScene = scnView.scene as? Scene12 {
            if gameScene.isFinished {
                // 1. Fade to black
                let fadeToBlackAction = SCNAction.run { [weak self] _ in
                    gameScene.fadeScreenToBlack(on: self!.view)
                }
                
                // 2. Run the fade-to-black action
                gameScene.rootNode.runAction(fadeToBlackAction) { [weak self] in
                    guard let self = self else { return }
                    print("Scene ended")
                    
                    // 3. Display "The End" text after the screen is black
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1-second delay to ensure screen is fully black
                        self.displayEndText(on: self.view)
                    }
                    
//                    // 4. Auto transition to another view controller after 5 seconds
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { // 5 seconds after showing "The End"
//                        self.transitionToNextViewController()
//                    }
                }
            }
        }
    }
    
    func displayEndText(on view: UIView?) {
        guard let view = view else { return }
        
        // Create a label
        let endLabel = UILabel()
        endLabel.text = "The End"
        endLabel.textColor = .white
        if let customFont = UIFont(name: "MetalMania-Regular", size: 40) {
            endLabel.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
        endLabel.textAlignment = .center
        endLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add the label to the view
        view.addSubview(endLabel)
        
        // Center the label in the view
        NSLayoutConstraint.activate([
            endLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            endLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func transitionToNextViewController() {
        // Replace "NextViewController" with your target view controller
        let nextVC = ViewController()
        nextVC.modalPresentationStyle = .fullScreen
        nextVC.modalTransitionStyle = .crossDissolve
        
        // Present the next view controller
        if let currentVC = UIApplication.shared.keyWindow?.rootViewController {
            currentVC.present(nextVC, animated: true, completion: nil)
        }
    }
    
    @objc func interactWithCake() {
        if let loadedScene = scnView.scene as? Scene6 {
            scene6 = loadedScene
        } else {
            print("Error: Scene6 not loaded correctly")
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
