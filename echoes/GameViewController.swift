// GameViewController.swift

import UIKit
import SceneKit
import GameplayKit

class GameViewController: UIViewController {
    static var shared = GameViewController()
    var scnView: SCNView!
    static var playerEntity: PlayerEntity!
    static var joystickComponent: VirtualJoystickComponent!
    
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
        
        // Set up the PlayerEntity
        if let gameScene = self.scnView.scene as? Scene2 {
            GameViewController.playerEntity = gameScene.playerEntity
            
            // Create a movement component to handle player movement, including the light node
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
            GameViewController.playerEntity.movementComponent = movementComponent
            
            GameViewController.joystickComponent.hideJoystick()
            
            // Link the joystick with the movement component
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
            }
            
            // Set up fog properties for the scene
            gameScene.fogStartDistance = 25.0   // Increase the start distance
            gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
            gameScene.fogDensityExponent = 0.2  // Reduce density to make the fog less thick
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
        }
        
        GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-15.538, -29.942, 0.728), duration: 3.0) {
            DispatchQueue.main.async {
                // Load Scene3 after the movement finishes
                SceneManager.shared.loadScene8()
                
                if let gameScene = self.scnView.scene as? Scene8 {
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
                    gameScene.fogDensityExponent = 0.2  // Reduce density to make the fog less thick
                    gameScene.fogColor = UIColor.black
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                }
            }
        }
    
        //SCENE 8
        if let gameScene = self.scnView.scene as? Scene8 {
            GameViewController.playerEntity = gameScene.playerEntity
            
            // Create a movement component to handle player movement, including the light node
            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
            GameViewController.playerEntity.movementComponent = movementComponent
             
            //ADD FOR STEPS TOILET IN SCENE8
            movementComponent.isToilet = true
            print("In Scene 8, isToilet is \(movementComponent.isToilet)")

            // Link the joystick with the movement component
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
            }
            
            // Set up fog properties for the scene
            gameScene.fogStartDistance = 25.0   // Increase the start distance
            gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
            gameScene.fogDensityExponent = 0.2  // Reduce density to make the fog less thick
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
        }
        
        // Configure the SCNView
        scnView.allowsCameraControl = false
        //        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor.black
        
        // Create and configure the interaction button
        interactButton = UIButton(type: .system)
        interactButton.setTitle("Play", for: .normal)
        // Load and apply the custom font for buttons
        if let customFont = UIFont(name: "SpecialElite-Regular", size: 14) {
            interactButton.titleLabel?.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
        interactButton.titleLabel?.numberOfLines = -1
        interactButton.titleLabel?.textAlignment = .center
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
        GameViewController.playerEntity?.movementComponent?.update(deltaTime: 0.016)
                
        if let gameScene = scnView.scene as? Scene4 {
            // Check if the player is near the transition point
            if gameScene.checkProximityToTransition() {
                // Load Scene6 after the movement finishes
                SceneManager.shared.loadScene5()
                
                if let gameScene = self.scnView.scene as? Scene5 {
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
        
        if let gameScene = scnView.scene as? Scene6 {
            // Loop through each puzzle piece
            for i in 1...6 {
                let puzzleNodeName = "Puzzle_\(i)"
                if let puzzleNode = gameScene.rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                    // Set the category bitmask for post-processing
                    puzzleNode.categoryBitMask = 2
                }
            }
            
            // Load and apply the SCNTechnique for the glow effect
            if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                let technique = SCNTechnique(dictionary: dict)
                
                // Optionally set a custom color for the glow
                let glowColor = SCNVector3(0.0, 1.0, 1.0)  // Cyan outline
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")
                
                scnView.technique = technique
            }
            
            gameScene.checkProximityToCake(interactButton: interactButton)  // Pass the button to the check
            
            if gameScene.isPlayingPuzzle {
                GameViewController.joystickComponent.joystickView.isHidden = true
            } else {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
            
            if gameScene.isPhotoObtained && gameScene.isCodeDone {
                gameScene.displayPhotoObtainedLabel(on: self.view)
                gameScene.isPhotoObtained = false
            } else if gameScene.isPuzzleFailed {
                gameScene.displayPhotoObtainedLabel(on: self.view)
                gameScene.isPuzzleFailed = false
            }
        }
        
        //SCENE 8
        if let gameScene = scnView.scene as? Scene8 {
            // Check if the player is near the transition point
            if gameScene.isJumpscareDone && gameScene.checkProximityToTransition() {
                // Load Scene9 after the movement finishes
//                SceneManager.shared.loadScene9()
//
//                if let gameScene = self.scnView.scene as? Scene9 {
//                    GameViewController.playerEntity = gameScene.playerEntity
//                    
//                    // Create a movement component to handle player movement, including the light node
//                    let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
//                    GameViewController.playerEntity.movementComponent = movementComponent
//                                        
//                    // Link the joystick with the movement component
//                    if let movementComponent = gameScene.playerEntity.movementComponent {
//                        movementComponent.joystickComponent = GameViewController.joystickComponent
//                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
//                    }
//                    
//                    // Set up fog properties for the scene
//                    gameScene.fogStartDistance = 25.0   // Increase the start distance
//                    gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
//                    gameScene.fogDensityExponent = 0.3  // Reduce density to make the fog less thick
//                    gameScene.fogColor = UIColor.black
//                    
//                    gameScene.setupGestureRecognizers(for: self.scnView)
//                }
            }

            let cabinetNodeName = "smallCabinet"
            if let cabinetNode = gameScene.rootNode.childNode(withName: cabinetNodeName, recursively: true) {
                // Set the category bitmask for post-processing
                cabinetNode.categoryBitMask = 2
            }
            
            let pipeNodeName = "pipe_1"
            if let pipeNode = gameScene.rootNode.childNode(withName: pipeNodeName, recursively: true) {
                // Set the category bitmask for post-processing
                pipeNode.categoryBitMask = 2
            }
            
            if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                let technique = SCNTechnique(dictionary: dict)

                // Optionally set a custom color for the glow
                let glowColor = SCNVector3(0.0, 1.0, 1.0)  // Cyan outline
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")

                scnView.technique = technique
            }
            
            gameScene.updateProximityAndGlow(interactButton: interactButton)
            
            if interactButton.titleLabel?.text == "Examine Pipe" && interactButton.isTouchInside {
                gameScene.isPipeClicked = true
            } else if interactButton.titleLabel?.text == "Open Cabinet" && interactButton.isTouchInside {
                gameScene.isCabinetOpened = true
            }

            if gameScene.isPlayingPipe || (!gameScene.isCabinetDone && gameScene.isCabinetOpened) || gameScene.isDollJumpscare {
                GameViewController.joystickComponent.joystickView.isHidden = true
                interactButton.isHidden = true
            } else if !gameScene.isCabinetOpened || (gameScene.isCabinetOpened && !gameScene.isPlayingPipe) || (!gameScene.isDollJumpscare && gameScene.isNecklaceObtained) {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
            
            if gameScene.isNecklaceFalling {
                gameScene.displayNecklaceObtainedLabel(on: self.view)
                gameScene.isNecklaceFalling = false
            } else if gameScene.isPipeFailed {
                gameScene.displayNecklaceObtainedLabel(on: self.view)
                gameScene.isPipeFailed = false
            }
        }
    }
    
    @objc func interactWithCake() {
        // Now check if the loaded scene is Scene1 and assign it to the scene1 variable
        if let loadedScene = scnView.scene as? Scene6 {
            loadedScene.displayPuzzlePieces(on: self.view)
            loadedScene.addOpenFridgeSound()
        } else {
            print("Error: Scene6 not loaded correctly")
        }
        
        if let loadedScene = scnView.scene as? Scene8 {
            if loadedScene.isPipeClicked {
                loadedScene.examinePipe(on: self.view)
                loadedScene.animatePipeToGreen(pipeName: "pipeclue-1")
            }
            
            if loadedScene.isCabinetOpened && !loadedScene.isCabinetDone {
                loadedScene.openCabinet()
            }
        } else {
            print("Error: Scene8 not loaded correctly")
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
