//  GameViewController.swift

import UIKit
import SceneKit
import GameplayKit
import AVKit
import AVFoundation


class GameViewController: UIViewController, Scene2Delegate {
    static var shared = GameViewController()
    static var playerEntity: PlayerEntity!
    static var joystickComponent: VirtualJoystickComponent!
    
    var scnView: SCNView!
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
            // Set delegate to handle Scene2 transition
            gameScene.delegate = self
            
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
        interactButton.titleLabel?.numberOfLines = -1
        interactButton.titleLabel?.textAlignment = .center
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
    
//    func transitionToScene10() {
//        SceneManager.shared.loadScene10()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            GameViewController.joystickComponent.showJoystick()
//        }
//        scnView.backgroundColor = UIColor.clear
//        
//        if let gameScene = self.scnView.scene as? Scene10 {
//            GameViewController.playerEntity = gameScene.playerEntity
//            
//            // Create a movement component to handle player movement, including the light node
//            let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode)
//            GameViewController.playerEntity.movementComponent = movementComponent
//            
//            // Link the joystick with the movement component
//            if let movementComponent = gameScene.playerEntity.movementComponent {
//                movementComponent.joystickComponent = GameViewController.joystickComponent
//                self.scnView.scene?.physicsWorld.contactDelegate = movementComponent
//            }
//            
//            // Set up fog properties for the scene
//            gameScene.fogStartDistance = 25.0
//            gameScene.fogEndDistance = 300.0
//            gameScene.fogDensityExponent = 0.2
//            gameScene.fogColor = UIColor.black
//            
//            gameScene.setupGestureRecognizers(for: self.scnView)
//            
//            // After scene loads, set the background back to black
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                self.scnView.backgroundColor = UIColor.black
//            }
//        }
//    }
    
    @objc func updateScene() {
        GameViewController.playerEntity?.movementComponent?.update(deltaTime: 0.016)
        
        if let gameScene = scnView.scene as? Scene4 {
            // Check if the player is near the transition point
            if gameScene.checkProximityToTransition() {
                if let doorNode = gameScene.rootNode.childNode(withName: "doorFamilyRoom", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "doorOpen.mp3", volume: 3, delay: 0)
                }
                
                // Load Scene6 after the movement finishes
                SceneManager.shared.loadScene5and6()
                
                if let gameScene = self.scnView.scene as? Scene5and6 {
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
                    gameScene.fogDensityExponent = 0.3  // Reduce density to make the fog less thick
                    gameScene.fogColor = UIColor.black
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                }
            }
        }
        
        if let gameScene = scnView.scene as? Scene5and6 {
            if gameScene.checkProximityToTransition() {
                if let doorNode = gameScene.rootNode.childNode(withName: "doorKiranaBedroom", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "door_open.mp3", volume: 3, delay: 0)
                }
                // Load Scene6 after the movement finishes
                SceneManager.shared.loadScene7()
                
                if let gameScene = self.scnView.scene as? Scene7 {
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
            
            if gameScene.isPlayingPuzzle || gameScene.isDollJumpscare {
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
            
            if gameScene.isDollJumpscare && !gameScene.isJumpscareDone {
                gameScene.displayJumpscareLabel(on: self.view)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
                    UIView.animate(withDuration: 0.5) {
                        gameScene.puzzleLabel.alpha = 0.0
                    }
                }
            }
        }
        
        //SCENE 8
        if let gameScene = scnView.scene as? Scene8 {
//             Check if the player is near the transition point
//            if gameScene.isJumpscareDone && gameScene.checkProximityToTransition() {
//                if let doorNode = gameScene.rootNode.childNode(withName: "doorFamilyRoom", recursively: true) {
//                    attachAudio(to: doorNode, audioFileName: "door_open.mp3", volume: 3, delay: 0)
//                }
//                // Load Scene9 after the movement finishes
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
//            }
            
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
            
            if gameScene.isDollJumpscare && !gameScene.isJumpscareDone {
                gameScene.displayJumpscareLabel(on: self.view)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    UIView.animate(withDuration: 0.5) {
                        gameScene.necklaceLabel.alpha = 0.0
                    }
                }
            }
        }
        
        // SCENE 7
        if let gameScene = scnView.scene as? Scene7 {
            
            if gameScene.checkProximityToTransition() {
                if let doorNode = gameScene.rootNode.childNode(withName: "doorToilet", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "door_open.mp3", volume: 3, delay: 0)
                }
                // Load Scene6 after the movement finishes
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
                    gameScene.fogDensityExponent = 0.5  // Reduce density to make the fog less thick
                    gameScene.fogColor = UIColor.black
                    
                    gameScene.setupGestureRecognizers(for: self.scnView)
                }
            }
            
            if let musicBoxNode = gameScene.rootNode.childNode(withName: "musicBox", recursively: true) {
                musicBoxNode.categoryBitMask = 2
            }
            
            if let phoneNode = gameScene.rootNode.childNode(withName: "phone", recursively: true) {
                phoneNode.categoryBitMask = 2
            }
            
            // Load and apply the SCNTechnique for the glow effect
            if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                let technique = SCNTechnique(dictionary: dict)

                let glowColor = SCNVector3(0.0, 1.0, 1.0)  // Cyan outline
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")

                scnView.technique = technique
            }
            
            // Check proximity to interactable objects and show button
            gameScene.updateProximityAndGlow(interactButton: interactButton)
            
            // Hide joystick and button when puzzle is open
            if gameScene.isPlayingPiano || gameScene.isOpenPhone {
                GameViewController.joystickComponent.joystickView.isHidden = true
                interactButton.isHidden = true  // Hide interact button
            } else {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }

            
            if gameScene.isGrandmaFinishedTalking || gameScene.isSwanLakePlaying{
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
            
            if gameScene.isGrandmaisTalking {
                GameViewController.joystickComponent.joystickView.isHidden = true
            }
        }
    }
    
    @objc func interactWithCake() {
        if let loadedScene = scnView.scene as? Scene5and6 {
            loadedScene.displayPuzzlePieces(on: self.view)
            loadedScene.addOpenFridgeSound()
        } else {
            print("Error: Scene5and6 not loaded correctly")
        }

        // Handle interactions in Scene7
        if let loadedScene = scnView.scene as? Scene7 {
            // Check if the piano puzzle has been completed
            if loadedScene.isPhonePuzzleCompleted {
                
                loadedScene.displayPianoPuzzle(on: self.view)
                loadedScene.isPuzzleDisplayed = true
                
                // Hide the interact button after the number pad is displayed
                interactButton.isHidden = true // Hide interact button
            } else {
                // If the music puzzle is not completed, display it
                loadedScene.displayNumberPad(on: self.view)
            }
        } else {
            print("Error: Scene7 not loaded correctly")
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
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        let waitAction = SCNAction.wait(duration: delay)
        let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
        node.runAction(sequenceAction)
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
