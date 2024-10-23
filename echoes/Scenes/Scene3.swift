//  Scene3.swift

import SceneKit
import UIKit

class Scene3: SCNScene {
    var playerEntity: PlayerEntity!
    var grandmaEntity: NPCEntity!
    var cameraComponent: CameraComponent?
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var doorNode: SCNNode?
    var grandmaNode: SCNNode?
    var scnView: SCNView?
    var isDoorOpen = false
    var isCutscenePlaying = false
    
    var doorOpenSound: SCNAudioSource!
    var doorCloseSound: SCNAudioSource!
    var andraGreetingsSound: SCNAudioSource!
    var grandmaGreetingsSound: SCNAudioSource!
    var andraThoughtsSound: SCNAudioSource!
    
    init(lightNode: SCNNode) {
        super.init()
        
        self.lightNode = lightNode
        loadAudioResources()
        
        guard let houseScene = SCNScene(named: "scene3.scn") else {
            print("Warning: House scene 'Scene3.scn' not found")
            return
        }
        
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        setupSceneComponents()
        attachAmbientSounds()
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        SCNTransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.forceSceneUpdateAndStart()
        }
    }
    
    func loadAudioResources() {
        doorOpenSound = SCNAudioSource(named: "door_open.MP3")
        andraGreetingsSound = SCNAudioSource(named: "scene3_andra_greetings.mp3")
        grandmaGreetingsSound = SCNAudioSource(named: "scene3_grandma_greetings.mp3")
        // andraThoughtsSound = SCNAudioSource(named: "scene3_andra_thoughts.mp3")
        doorCloseSound = SCNAudioSource(named: "door_close.MP3")
        
        [doorOpenSound, andraGreetingsSound, grandmaGreetingsSound, doorCloseSound].forEach {
            if let source = $0 {
                source.shouldStream = false
                source.loops = false
                source.volume = 1.0
                print("Loaded audio source: \(source)")
            } else {
                print("Error loading audio source")
            }
        }
    }
    
    func setupSceneComponents() {
        doorNode = rootNode.childNode(withName: "Door", recursively: true)
        grandmaNode = rootNode.childNode(withName: "Grandma", recursively: true)
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }
        rootNode.addChildNode(playerNode)
        
        if let cameraNode = playerNode.childNode(withName: "Camera", recursively: true) {
            self.cameraNode = cameraNode
        } else {
            self.cameraNode = SCNNode()
            let camera = SCNCamera()
            camera.fieldOfView = 75
            self.cameraNode.camera = camera
            playerNode.addChildNode(self.cameraNode)
        }
        
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        rootNode.addChildNode(lightNode)
        
//        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
//        playerEntity.addComponent(movementComponent)
        
        let playerLightNode = SCNNode()
        let grandmaLightNode = SCNNode()
        
        playerLightNode.light = SCNLight()
        grandmaLightNode.light = SCNLight()
        
        // Add EcholocationComponent to player and grandma
        let playerEcholocationComponent = EcholocationComponent(lightNode: playerLightNode)
        playerEntity.addComponent(playerEcholocationComponent)
        
        // Add grandma entity and its echolocation component
        grandmaEntity = NPCEntity(npcNode: grandmaNode, lightNode: grandmaLightNode)
        
        rootNode.addChildNode(playerLightNode)
        rootNode.addChildNode(grandmaLightNode)
    }
    
    func forceSceneUpdateAndStart() {
        guard let scnView = self.scnView else {
            print("SCNView not assigned")
            return
        }
        
        scnView.isPlaying = true
        scnView.scene?.isPaused = false
        scnView.sceneTime = 0
        
        cameraComponent?.lockCamera()
        startCutscene()
    }
    
    func attachAmbientSounds() {
        if let windNode = rootNode.childNode(withName: "wind", recursively: true) {
            attachAudio(to: windNode, audioFileName: "wind.wav", volume: 0.1)
        }
        
        if let crowNode = rootNode.childNode(withName: "crow", recursively: true) {
            attachAudio(to: crowNode, audioFileName: "crow.wav", volume: 0.1)
        }
        
        if let lightRainNode = rootNode.childNode(withName: "lightRain", recursively: true) {
            attachAudio(to: lightRainNode, audioFileName: "outsideRain.wav", volume: 0.1)
        }
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float = 1.0) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.loops = true
        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        node.runAction(playAudioAction)
    }
    
    func startCutscene() {
        isCutscenePlaying = true
        let delayAction = SCNAction.wait(duration: 0.5)
        let sequence = SCNAction.sequence([delayAction, SCNAction.run { [weak self] _ in
            self?.openDoor {
                self?.moveGrandma {
                    self?.playDialogues()
                }
            }
        }])
        rootNode.runAction(sequence)
    }
    
    func openDoor(completion: @escaping () -> Void) {
        guard let doorNode = doorNode else { return }
        
        let openDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: 2.5)
        openDoorAction.timingMode = .easeInEaseOut
        
        let playSoundAction = SCNAction.playAudio(doorOpenSound, waitForCompletion: false)
        
        // Activate the player's echolocation flash effect
        if let echolocationComponent = playerEntity.component(ofType: EcholocationComponent.self) {
            echolocationComponent.activateFlash()
        }
        
        // Group the door rotation and sound action
        let doorSequence = SCNAction.group([openDoorAction, playSoundAction])
        
        doorNode.runAction(doorSequence) {
            completion()
        }
        isDoorOpen = true
    }
    
    func moveGrandma(completion: @escaping () -> Void) {
        guard let grandmaNode = grandmaNode else { return }
        let targetPosition = SCNVector3(x: 0, y: -10, z: 0)
        let moveAction = SCNAction.move(to: targetPosition, duration: 2.5)
        
        grandmaEntity.activateEcholocation()
        
        grandmaNode.runAction(moveAction) {
            completion()
        }
    }
    
    func playDialogues() {
        print("Starting dialogues...")
        
        // Ensure that all audio sources are loaded and ready
        guard let andraGreetingsSound = andraGreetingsSound,
              let grandmaGreetingsSound = grandmaGreetingsSound else {
            print("One or more audio sources not loaded properly")
            return
        }
        
        andraGreetingsSound.loops = false
        grandmaGreetingsSound.loops = false
        
        // Play first dialogue (Andra greetings)
        playAudioSource(andraGreetingsSound, volume: 5.0) {
            print("Andra greetings finished")
            
            let delayAction = SCNAction.wait(duration: 2.0)
            self.rootNode.runAction(delayAction) {
                // Play second dialogue (Grandma greetings)
                self.playAudioSource(self.grandmaGreetingsSound, volume: 8.0) {
                    print("Grandma greetings finished")
                    
                    self.playDoorCloseSoundAndFadeToBlack()
                }
            }
        }
    }
    
    func playDoorCloseSoundAndFadeToBlack() {
        guard scnView != nil else { return }
        
        let playSoundAction = SCNAction.playAudio(doorCloseSound, waitForCompletion: false)
        let fadeToBlackAction = SCNAction.run { [weak self] _ in
            self?.fadeScreenToBlack()
        }
        
        let groupAction = SCNAction.group([playSoundAction])
        rootNode.runAction(groupAction) {
            DispatchQueue.main.async {
                // Load Scene3 after the movement finishes
                SceneManager.shared.loadScene4()
                
                if let gameScene = self.scnView?.scene as? Scene4 {
                    GameViewController.playerEntity = gameScene.playerEntity
        
                    // Create a movement component to handle player movement, including the light node
                    let movementComponent = MovementComponent(playerNode: gameScene.playerEntity.playerNode!, cameraNode: gameScene.cameraNode, lightNode: gameScene.lightNode) // Pass lightNode
                    GameViewController.playerEntity.movementComponent = movementComponent
        
                    // Link the joystick with the movement component
                    if let movementComponent = gameScene.playerEntity.movementComponent {
                        movementComponent.joystickComponent = GameViewController.joystickComponent
                        self.scnView?.scene?.physicsWorld.contactDelegate = movementComponent // Set the physics delegate
                    }
        
                    // Set up fog properties for the scene
                    gameScene.fogStartDistance = 25.0   // Increase the start distance
                    gameScene.fogEndDistance = 300.0    // Increase the end distance to make the fog more gradual
                    gameScene.fogDensityExponent = 0.2  // Reduce density to make the fog less thick
                    gameScene.fogColor = UIColor.black
        
                    gameScene.setupGestureRecognizers(for: self.scnView!)
                }
            }
        }
    }
    
    func fadeScreenToBlack() {
        guard let scnView = scnView else { return }
        
        DispatchQueue.main.async {
            let blackOverlay = UIView(frame: scnView.bounds)
            blackOverlay.backgroundColor = .black
            blackOverlay.alpha = 0
            scnView.addSubview(blackOverlay)
            
            UIView.animate(withDuration: 2.0) {
                blackOverlay.alpha = 1.0
            } completion: { _ in
                print("Scene 3 ended")
            }
        }
    }
    
    func playAudioSource(_ audioSource: SCNAudioSource, volume: Float, completion: @escaping () -> Void) {
        audioSource.volume = volume
        audioSource.isPositional = false
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        rootNode.runAction(playAudioAction) {
            completion()
        }
    }
    
    func setupGestureRecognizers(for view: SCNView) {
        self.scnView = view
        guard let cameraComponent = cameraComponent else {
            print("Error: CameraComponent is nil. Cannot set up gesture recognizers.")
            return
        }
        view.isPlaying = true
        view.scene?.isPaused = false
        
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
