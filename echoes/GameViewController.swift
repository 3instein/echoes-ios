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
    static var isGrandmaPicked: Bool = false
    static var isRezaPicked: Bool = false
    static var isAyuPicked: Bool = false
    static var isCauseCorrect: Bool = false
    static var previousPlayerChoice: String? = "Ayu" // This can be "Ayu" or "Reza"
    
    var scnView: SCNView!
    var interactButton: UIButton!
    var isTransitioning: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GameViewController.shared = self
        
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
        
        // Scene 2
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
            gameScene.fogStartDistance = 100.0
            gameScene.fogEndDistance = 300.0
            gameScene.fogDensityExponent = 0.2
            gameScene.fogColor = UIColor.black
            
            gameScene.setupGestureRecognizers(for: self.scnView)
            
            // Start the walking sequence and cutscene in Scene2
            gameScene.startWalkingToHouse()
        }
        
        // Configure the SCNView
        scnView.allowsCameraControl = false
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
    
    @objc func updateScene() {
        GameViewController.playerEntity?.movementComponent?.update(deltaTime: 0.016)
        
        // Scene 4
        if let gameScene = scnView.scene as? Scene4 {
            // Ensure the transition logic is executed only once
            if !isTransitioning && gameScene.checkProximityToTransition() {
                isTransitioning = true
                GameViewController.joystickComponent.hideJoystick()
                
                // Play the door opening sound
                if let doorNode = gameScene.rootNode.childNode(withName: "doorFamilyRoom", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "doorOpen.MP3", volume: 3, delay: 0)
                }
                
                // Display the loading screen
                let loadingView = LoadingView(frame: scnView.bounds)
                scnView.addSubview(loadingView)
                loadingView.fadeIn { [weak self] in
                    guard let self = self else { return }
                    
                    // Clean up the current scene first
                    SceneManager.shared.cleanupCurrentScene()
                    
                    // Preload Scene5and6 assets
                    AssetPreloader.preloadScenes5and6 { success in
                        DispatchQueue.main.async {
                            if success {
                                print("Scene5and6 assets successfully prepared.")
                                
                                // Load Scene5and6
                                SceneManager.shared.loadScene5and6()
                                
                                // Configure Scene5and6 after loading
                                if let gameScene = self.scnView.scene as? Scene5and6 {
                                    GameViewController.playerEntity = gameScene.playerEntity
                                    
                                    // Create a movement component to handle player movement, including the light node
                                    let movementComponent = MovementComponent(
                                        playerNode: gameScene.playerEntity.playerNode!,
                                        cameraNode: gameScene.cameraNode,
                                        lightNode: gameScene.lightNode
                                    )
                                    GameViewController.playerEntity.movementComponent = movementComponent
                                    
                                    // Link the joystick with the movement component
                                    if let movementComponent = gameScene.playerEntity.movementComponent {
                                        movementComponent.joystickComponent = GameViewController.joystickComponent
                                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
                                    }
                                    
                                    // Set up fog properties for the scene
                                    gameScene.fogStartDistance = 25.0
                                    gameScene.fogEndDistance = 300.0
                                    gameScene.fogDensityExponent = 0.3
                                    gameScene.fogColor = UIColor.black
                                    
                                    // Configure gesture recognizers
                                    gameScene.setupGestureRecognizers(for: self.scnView)
                                }
                                
                                // Stop the loading screen after Scene5and6 is fully loaded
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    loadingView.stopLoading()
                                    GameViewController.joystickComponent.showJoystick()
                                }
                            } else {
                                print("Error: Failed to prepare Scene5and6 assets.")
                                loadingView.stopLoading()
                            }
                            
                            // Reset the transition state
                            self.isTransitioning = false
                        }
                    }
                }
            }
        }
        
        // Scene 5 and 6
        if let gameScene = scnView.scene as? Scene5and6 {
            // Ensure the transition logic is executed only once
            if !isTransitioning && gameScene.checkProximityToTransition() {
                isTransitioning = true
                GameViewController.joystickComponent.hideJoystick()
                
                // Play the door opening sound
                if let doorNode = gameScene.rootNode.childNode(withName: "doorKiranaBedroom", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "doorOpen.MP3", volume: 3, delay: 0)
                }
                
                // Display the loading screen
                let loadingView = LoadingView(frame: scnView.bounds)
                scnView.addSubview(loadingView)
                loadingView.fadeIn { [weak self] in
                    guard let self = self else { return }
                    
                    // Clean up the current scene first
                    SceneManager.shared.cleanupCurrentScene()
                    
                    // Preload Scene7 assets
                    AssetPreloader.preloadScene7 { success in
                        DispatchQueue.main.async {
                            if success {
                                print("Scene7 assets successfully prepared.")
                                
                                // Load Scene7
                                SceneManager.shared.loadScene7()
                                
                                // Configure Scene7 after loading
                                if let gameScene = self.scnView.scene as? Scene7 {
                                    GameViewController.playerEntity = gameScene.playerEntity
                                    
                                    // Create a movement component to handle player movement, including the light node
                                    let movementComponent = MovementComponent(
                                        playerNode: gameScene.playerEntity.playerNode!,
                                        cameraNode: gameScene.cameraNode,
                                        lightNode: gameScene.lightNode
                                    )
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
                                    
                                    // Configure gesture recognizers
                                    gameScene.setupGestureRecognizers(for: self.scnView)
                                }
                                
                                // Stop the loading screen after Scene7 is fully loaded
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    loadingView.stopLoading()
                                    GameViewController.joystickComponent.showJoystick()
                                }
                            } else {
                                print("Error: Failed to prepare Scene7 assets.")
                                loadingView.stopLoading()
                            }
                            
                            // Reset the transition state
                            self.isTransitioning = false
                        }
                    }
                }
            }
            
            // Load and apply the SCNTechnique for the glow effect
            if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                let technique = SCNTechnique(dictionary: dict)
                
                // Optionally set a custom color for the glow
                let glowColor = SCNVector3(0.0, 1.0, 1.0)
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")
                
                scnView.technique = technique
            }
            
            gameScene.checkProximityToCake(interactButton: interactButton)
            
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
        
        // Scene 7
        if let gameScene = scnView.scene as? Scene7 {
            // Ensure the transition logic is executed only once
            if !isTransitioning && gameScene.checkProximityToTransition() {
                isTransitioning = true
                GameViewController.joystickComponent.hideJoystick()
                
                // Play the door opening sound
                if let doorNode = gameScene.rootNode.childNode(withName: "doorToilet", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "doorOpen.MP3", volume: 3, delay: 0)
                }
                
                // Display the loading screen
                let loadingView = LoadingView(frame: scnView.bounds)
                scnView.addSubview(loadingView)
                loadingView.fadeIn { [weak self] in
                    guard let self = self else { return }
                    
                    // Clean up the current scene first
                    SceneManager.shared.cleanupCurrentScene()
                    
                    // Preload Scene8 assets
                    AssetPreloader.preloadScene8 { success in
                        DispatchQueue.main.async {
                            if success {
                                print("Scene8 assets successfully prepared.")
                                
                                // Load Scene8
                                SceneManager.shared.loadScene8()
                                
                                // Configure Scene8 after loading
                                if let gameScene = self.scnView.scene as? Scene8 {
                                    GameViewController.playerEntity = gameScene.playerEntity
                                    
                                    // Create a movement component to handle player movement, including the light node
                                    let movementComponent = MovementComponent(
                                        playerNode: gameScene.playerEntity.playerNode!,
                                        cameraNode: gameScene.cameraNode,
                                        lightNode: gameScene.lightNode
                                    )
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
                                    
                                    // Configure gesture recognizers
                                    gameScene.setupGestureRecognizers(for: self.scnView)
                                }
                                
                                // Stop the loading screen after Scene8 is fully loaded
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    loadingView.stopLoading()
                                    GameViewController.joystickComponent.showJoystick()
                                }
                            } else {
                                print("Error: Failed to prepare Scene8 assets.")
                                loadingView.stopLoading()
                            }
                            
                            // Reset the transition state
                            self.isTransitioning = false
                        }
                    }
                }
            }
            
            // Configure glow effect for specific nodes
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
                
                let glowColor = SCNVector3(0.0, 1.0, 1.0) // Cyan outline
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")
                
                scnView.technique = technique
            }
            
            // Check proximity to interactable objects and show button
            gameScene.updateProximityAndGlow(interactButton: interactButton)
            
            // Hide joystick and button when a puzzle is open
            if gameScene.isPlayingPiano || gameScene.isOpenPhone {
                GameViewController.joystickComponent.joystickView.isHidden = true
                interactButton.isHidden = true // Hide interact button
            } else {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
            
            if gameScene.isGrandmaFinishedTalking || gameScene.isSwanLakePlaying {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
            
            if gameScene.isGrandmaisTalking {
                GameViewController.joystickComponent.joystickView.isHidden = true
            }
        }
        
        // Scene 8
        if let gameScene = scnView.scene as? Scene8 {
            // Ensure the transition logic is executed only once
            if !isTransitioning && gameScene.isJumpscareDone && gameScene.checkProximityToTransition() {
                isTransitioning = true
                GameViewController.joystickComponent.hideJoystick()
                
                // Play the door opening sound
                if let doorNode = gameScene.rootNode.childNode(withName: "doorFamilyRoom", recursively: true) {
                    attachAudio(to: doorNode, audioFileName: "doorOpen.MP3", volume: 3, delay: 0)
                }
                
                // Display the loading screen
                let loadingView = LoadingView(frame: scnView.bounds)
                scnView.addSubview(loadingView)
                loadingView.fadeIn { [weak self] in
                    guard let self = self else { return }
                    
                    // Clean up the current scene first
                    SceneManager.shared.cleanupCurrentScene()
                    
                    // Preload Scene9 assets
                    AssetPreloader.preloadScene9 { success in
                        DispatchQueue.main.async {
                            if success {
                                print("Scene9 assets successfully prepared.")
                                
                                // Load Scene 9
                                SceneManager.shared.loadScene9()
                                
                                // Configure Scene9 after loading
                                if let gameScene = self.scnView.scene as? Scene9 {
                                    GameViewController.playerEntity = gameScene.playerEntity
                                    
                                    // Create a movement component to handle player movement, including the light node
                                    let movementComponent = MovementComponent(
                                        playerNode: gameScene.playerEntity.playerNode!,
                                        cameraNode: gameScene.cameraNode,
                                        lightNode: gameScene.lightNode
                                    )
                                    GameViewController.playerEntity.movementComponent = movementComponent
                                    
                                    // Link the joystick with the movement component
                                    if let movementComponent = gameScene.playerEntity.movementComponent {
                                        movementComponent.joystickComponent = GameViewController.joystickComponent
                                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
                                    }
                                    
                                    // Set up fog properties for the scene
                                    gameScene.fogStartDistance = 25.0
                                    gameScene.fogEndDistance = 300.0
                                    gameScene.fogDensityExponent = 0.3
                                    gameScene.fogColor = UIColor.black
                                    
                                    // Configure gesture recognizers
                                    gameScene.setupGestureRecognizers(for: self.scnView)
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    loadingView.stopLoading()
                                    GameViewController.joystickComponent.showJoystick()
                                }
                            } else {
                                print("Error: Failed to prepare Scene9 assets.")
                                loadingView.stopLoading()
                            }
                            
                            // Reset the transition state
                            self.isTransitioning = false
                        }
                    }
                }
            }
            
            // Set the category bitmask for cabinet and pipe nodes for post-processing
            if let cabinetNode = gameScene.rootNode.childNode(withName: "smallCabinet", recursively: true) {
                cabinetNode.categoryBitMask = 2
            }
            
            if let pipeNode = gameScene.rootNode.childNode(withName: "pipe_1", recursively: true) {
                pipeNode.categoryBitMask = 2
            }
            
            // Load and apply the SCNTechnique for the glow effect
            if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                let technique = SCNTechnique(dictionary: dict)
                
                let glowColor = SCNVector3(0.0, 1.0, 1.0) // Cyan outline
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")
                
                scnView.technique = technique
            }
            
            // Update proximity and glow for interactable objects
            gameScene.updateProximityAndGlow(interactButton: interactButton)
            
            // Handle button interactions
            if interactButton.titleLabel?.text == "Examine Pipe" && interactButton.isTouchInside {
                gameScene.isPipeClicked = true
            } else if interactButton.titleLabel?.text == "Open Cabinet" && interactButton.isTouchInside {
                gameScene.isCabinetOpened = true
            }
            
            // Toggle joystick and button visibility based on game state
            if gameScene.isPlayingPipe || (!gameScene.isCabinetDone && gameScene.isCabinetOpened) || gameScene.isDollJumpscare {
                GameViewController.joystickComponent.joystickView.isHidden = true
                interactButton.isHidden = true
            } else if !gameScene.isCabinetOpened || (gameScene.isCabinetOpened && !gameScene.isPlayingPipe) || (!gameScene.isDollJumpscare && gameScene.isNecklaceObtained) {
                GameViewController.joystickComponent.joystickView.isHidden = false
            }
            
            // Handle necklace or pipe game state
            if gameScene.isNecklaceFalling {
                gameScene.displayNecklaceObtainedLabel(on: self.view)
                gameScene.isNecklaceFalling = false
            } else if gameScene.isPipeFailed {
                gameScene.displayNecklaceObtainedLabel(on: self.view)
                gameScene.isPipeFailed = false
            }
            
            // Handle jumpscare events
            if gameScene.isDollJumpscare && !gameScene.isJumpscareDone {
                gameScene.displayJumpscareLabel(on: self.view)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                    UIView.animate(withDuration: 0.5) {
                        gameScene.necklaceLabel.alpha = 0.0
                    }
                }
            }
        }
        
        // Scene 9
        if let gameScene = scnView.scene as? Scene9 {
            print("Currently in Scene9. Checking proximity to winning point...")
            
            if !isTransitioning && gameScene.checkProximityToWinningPoint() {
                print("Player is close enough to the winning point. Preparing transition to Scene10...")
                isTransitioning = true
                
                // Hide joystick and prepare loading view
                GameViewController.joystickComponent.hideJoystick()
                let loadingView = LoadingView(frame: scnView.bounds)
                scnView.addSubview(loadingView)
                
                // Fade in the loading view and transition to Scene10
                loadingView.fadeIn { [weak self] in
                    guard let self = self else { return }
                    SceneManager.shared.cleanupCurrentScene()
                    
                    AssetPreloader.preloadScene10 { success in
                        DispatchQueue.main.async {
                            loadingView.stopLoading()
                            if success {
                                print("Scene10 assets loaded successfully.")
                                self.loadScene10()
                            } else {
                                print("Error: Failed to preload Scene10.")
                                self.isTransitioning = false // Allow retry
                            }
                        }
                        // Reset the transition state
                        self.isTransitioning = false
                    }
                }
            }
        }
        
        // Scene 10
        if let gameScene = scnView.scene as? Scene10 {
            gameScene.checkProximity()
            
            if !isTransitioning && gameScene.checkProximityToTransition() {
                startTransitionToScene11()
            }
        }
        
        // Scene 11
        if let gameScene = scnView.scene as? Scene11 {
            // print(gameScene.isDeathPicked)
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) { [weak self] in
                gameScene.showPurpleBackgroundOverlay(in: self?.view ?? UIView())
            }
            
            if gameScene.isDeathPicked {
                isTransitioning = true
                GameViewController.joystickComponent.hideJoystick()
                
                // Display loading view
                let loadingView = LoadingView(frame: scnView.bounds)
                scnView.addSubview(loadingView)
                loadingView.fadeIn { [weak self] in
                    guard let self = self else { return }
                    SceneManager.shared.cleanupCurrentScene()
                    
                    AssetPreloader.preloadScene12 { success in
                        DispatchQueue.main.async {
                            if success {
                                // Load Scene12
                                SceneManager.shared.loadScene12()
                                
                                // Configure Scene12
                                if let gameScene = self.scnView.scene as? Scene12 {
                                    GameViewController.playerEntity = gameScene.playerEntity
                                    
                                    // Set up movement component
                                    let movementComponent = MovementComponent(
                                        playerNode: gameScene.playerEntity.playerNode!,
                                        cameraNode: gameScene.cameraNode,
                                        lightNode: gameScene.lightNode
                                    )
                                    GameViewController.playerEntity.movementComponent = movementComponent
                                    
                                    if let movementComponent = gameScene.playerEntity.movementComponent {
                                        movementComponent.joystickComponent = GameViewController.joystickComponent
                                        self.scnView.scene?.physicsWorld.contactDelegate = movementComponent
                                    }
                                    
                                    gameScene.setupGestureRecognizers(for: self.scnView)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) { [weak self] in
                                        gameScene.setupAndStartSlideshow(on: self?.view ?? UIView())
                                    }
                                }
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    loadingView.stopLoading()
                                }
                            } else {
                                print("Error: Failed to preload Scene12.")
                                loadingView.stopLoading()
                            }
                            
                            // Reset the transition state
                            self.isTransitioning = false
                        }
                    }
                }
            }
        }
        
        // Scene 12
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.displayEndText(on: self.view)
                    }
                    
                    // 4. Auto transition to another view controller after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                        self.transitionToNextViewController()
                    }
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
    
    func loadScene10() {
        SceneManager.shared.loadScene10()
        
        // Configure Scene10
        if let gameScene = scnView.scene as? Scene10 {
            GameViewController.playerEntity = gameScene.playerEntity
            
            let movementComponent = MovementComponent(
                playerNode: gameScene.playerEntity.playerNode!,
                cameraNode: gameScene.cameraNode,
                lightNode: gameScene.lightNode
            )
            GameViewController.playerEntity.movementComponent = movementComponent
            
            if let movementComponent = gameScene.playerEntity.movementComponent {
                movementComponent.joystickComponent = GameViewController.joystickComponent
                scnView.scene?.physicsWorld.contactDelegate = movementComponent
            }
            
            gameScene.setupGestureRecognizers(for: scnView)
            print("Scene10 loaded successfully.")
            
            DispatchQueue.main.async {
                if let runButton = self.view.subviews.first(where: { $0 is UIButton && ($0 as? UIButton)?.title(for: .normal) == "Run" }) {
                    runButton.removeFromSuperview()
                    print("Run button removed from Scene10.")
                }
            }
            
            DispatchQueue.main.async {
                self.scnView.subviews.forEach { subview in
                    if let loadingView = subview as? LoadingView {
                        loadingView.stopLoading()
                        GameViewController.joystickComponent.showJoystick()
                        loadingView.removeFromSuperview()
                    }
                }
            }
        } else {
            print("Error: Scene10 not loaded correctly.")
        }
    }
    
    func startTransitionToScene11() {
        isTransitioning = true
        GameViewController.joystickComponent.hideJoystick()
        
        // Display the loading screen
        let loadingView = LoadingView(frame: scnView.bounds)
        scnView.addSubview(loadingView)
        loadingView.fadeIn { [weak self] in
            guard let self = self else {
                print("GameViewController is nil during transition to Scene11.")
                return
            }
            print("Loading view displayed.")
            SceneManager.shared.cleanupCurrentScene()
            
            AssetPreloader.preloadScene11 { success in
                DispatchQueue.main.async {
                    if success {
                        print("Scene11 assets successfully prepared.")
                        
                        // Load Scene11
                        SceneManager.shared.loadScene11()
                        
                        // Configure Scene11 after loading
                        if let gameScene = self.scnView.scene as? Scene11 {
                            GameViewController.playerEntity = gameScene.playerEntity
                            print("Scene11 loaded successfully.")
                            
                            // Set up movement components
                            let movementComponent = MovementComponent(
                                playerNode: gameScene.playerEntity.playerNode!,
                                cameraNode: gameScene.cameraNode,
                                lightNode: gameScene.lightNode
                            )
                            GameViewController.playerEntity.movementComponent = movementComponent
                            
                            if let movementComponent = gameScene.playerEntity.movementComponent {
                                movementComponent.joystickComponent = GameViewController.joystickComponent
                                self.scnView.scene?.physicsWorld.contactDelegate = movementComponent
                            }
                            
                            gameScene.setupGestureRecognizers(for: self.scnView)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            loadingView.stopLoading()
                        }
                    } else {
                        print("Error: Failed to prepare Scene11 assets.")
                        self.isTransitioning = false // Allow retry
                    }
                    
                    // Reset the transition state
                    self.isTransitioning = false
                }
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
    
    func transitionToScene4() {
        SceneManager.shared.loadScene4()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            GameViewController.joystickComponent.showJoystick()
        }
        GameViewController.joystickComponent.showBasicTutorial()
        
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
