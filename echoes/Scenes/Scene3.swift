// Scene3.swift

import SceneKit
import UIKit

class Scene3: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent?
    var lightNode: SCNNode!
    var doorNode: SCNNode?
    var grandmaNode: SCNNode?
    var scnView: SCNView?
    var isDoorOpen = false
    var isCutscenePlaying = false
    
    // Preloaded audio sources for efficiency
    var doorOpenSound: SCNAudioSource!
    var doorCloseSound: SCNAudioSource!
    var andraGreetingsSound: SCNAudioSource!
    var grandmaGreetingsSound: SCNAudioSource!
    var andraThoughtsSound: SCNAudioSource!
    
    // Scene initializer with lightNode as an external dependency
    init(lightNode: SCNNode) {
        super.init()
        
        self.lightNode = lightNode
        loadAudioResources() // Preload audio sources
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene3.scn") else {
            print("Warning: House scene 'Scene3.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        setupSceneComponents()
        attachAmbientSounds()
        
        // Ensure the scene updates happen immediately, without waiting for user interaction
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        SCNTransaction.commit()
        
        // Start the rendering loop
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.forceSceneUpdateAndStart()
        }
    }
    
    // Load and cache audio resources to avoid reloading during runtime
    func loadAudioResources() {
        doorOpenSound = SCNAudioSource(named: "door_open.MP3")
        doorCloseSound = SCNAudioSource(named: "door_close.MP3")
        andraGreetingsSound = SCNAudioSource(named: "scene3_andra_greetings.mp3")
        grandmaGreetingsSound = SCNAudioSource(named: "scene3_grandma_greetings.mp3")
        andraThoughtsSound = SCNAudioSource(named: "scene3_andra_thoughts.mp3")
        
        [doorOpenSound, doorCloseSound, andraGreetingsSound, grandmaGreetingsSound, andraThoughtsSound].forEach {
            $0?.load()
        }
    }
    
    // Function to set up player entity, camera, lighting, etc.
    func setupSceneComponents() {
        // Find the door and grandma nodes in the scene
        doorNode = rootNode.childNode(withName: "Door", recursively: true)
        grandmaNode = rootNode.childNode(withName: "Grandma", recursively: true)
        
        // Create a new player entity and initialize it using the house scene's root node
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }
        
        // Add player node to the GameScene's rootNode
        rootNode.addChildNode(playerNode)
        
        // Attach the existing camera node from the player model to the scene, or create one if missing
        if let cameraNode = playerNode.childNode(withName: "Camera", recursively: true) {
            self.cameraNode = cameraNode
        } else {
            // Create a new camera node if not present
            self.cameraNode = SCNNode()
            let camera = SCNCamera()
            camera.fieldOfView = 75
            self.cameraNode.camera = camera
            playerNode.addChildNode(self.cameraNode)
        }
        
        // Initialize cameraComponent with a valid cameraNode
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        // Temporarily illuminate the scene with ambient lighting
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 200
        ambientLight.color = UIColor.white
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)
        
        // Add the external light node to the scene
        rootNode.addChildNode(lightNode)
        
        // Initialize MovementComponent with lightNode reference
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
    }
    
    // Force the SCNView to update and play the scene
    func forceSceneUpdateAndStart() {
        guard let scnView = self.scnView else { return }
        
        scnView.isPlaying = true // Start the rendering loop
        scnView.scene?.isPaused = false // Unpause the scene if paused
        scnView.sceneTime = 0           // Reset the scene time to zero
        
        // Start the cutscene after forcing an update
        startCutscene()
    }
    
    // Function to attach wind, crow, and lightRain sounds with reduced volume
    func attachAmbientSounds() {
        if let windNode = rootNode.childNode(withName: "wind", recursively: true) {
            attachAudio(to: windNode, audioFileName: "wind.wav", volume: 0.1)
        }
        
        if let crowNode = rootNode.childNode(withName: "crow", recursively: true) {
            attachAudio(to: crowNode, audioFileName: "crow.wav", volume: 0.1)
        }
        
        if let lightRainNode = rootNode.childNode(withName: "lightRain", recursively: true) {
            attachAudio(to: lightRainNode, audioFileName: "lightRain.wav", volume: 0.1)
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
        
        // Sequence of actions: delay, open door with sound, then move grandma, followed by dialogues and door closing
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
        
        let openDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: 2.0)
        let playSoundAction = SCNAction.playAudio(doorOpenSound, waitForCompletion: false)
        
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
        
        grandmaNode.runAction(moveAction) {
            completion()
        }
    }
    
    func playDialogues() {
        playAudioSource(andraGreetingsSound, volume: 4.0) {
            self.playAudioSource(self.grandmaGreetingsSound, volume: 4.0) {
                self.playAudioSource(self.andraThoughtsSound, volume: 4.0) {
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
        
        let groupAction = SCNAction.group([playSoundAction, fadeToBlackAction])
        rootNode.runAction(groupAction)
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
    
    // Helper function to play preloaded audio
    func playAudioSource(_ audioSource: SCNAudioSource, volume: Float, completion: @escaping () -> Void) {
        audioSource.volume = volume
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
        
        // Ensure the rendering loop is running and scene is active
        view.isPlaying = true
        view.scene?.isPaused = false
        
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
