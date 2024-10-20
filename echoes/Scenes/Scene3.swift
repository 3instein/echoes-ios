//  Scene3.swift

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
    
    // Scene initializer with lightNode as an external dependency
    init(lightNode: SCNNode) {
        super.init()
        
        self.lightNode = lightNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene3.scn") else {
            print("Warning: House scene 'Scene3.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
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
        
        // Attach the existing camera node from the player model to the scene
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
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
        
        // Attach ambient sounds
        attachAmbientSounds()
        
        // Force SceneKit to update the scene immediately
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        SCNTransaction.commit()
        
        // Start the cutscene automatically without user interaction
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
        disablePlayerMovement()
        
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
    
    func disablePlayerMovement() {
        // Disable player movement during cutscene
        // playerEntity.movementComponent.isEnabled = false
    }
    
    func enablePlayerMovement() {
        // Re-enable player movement after cutscene
        // playerEntity.movementComponent.isEnabled = true
    }
    
    func openDoor(completion: @escaping () -> Void) {
        guard let doorNode = doorNode else { return }
        
        let doorOpenSound = SCNAudioSource(named: "door_open.MP3")!
        doorOpenSound.load()
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
        
        grandmaNode.runAction(moveAction) { [weak self] in
            self?.enablePlayerMovement()
            self?.isCutscenePlaying = false
            completion()
        }
    }
    
    func playDialogues() {
        // Player greets grandma
        playAudio(named: "scene3_andra_greetings.mp3", volume: 3.0) {
            // Grandma replies
            self.playAudio(named: "scene3_grandma_greetings.mp3", volume: 2.0) {
                // Player's thoughts
                self.playAudio(named: "scene3_andra_thoughts.mp3", volume: 3.0) {
                    // Play door closing sound and fade to black
                    self.playDoorCloseSoundAndFadeToBlack()
                }
            }
        }
    }
    
    func playDoorCloseSoundAndFadeToBlack() {
        guard scnView != nil else { return }
        let doorCloseSound = SCNAudioSource(named: "door_close.MP3")!
        doorCloseSound.load()
        
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
    
    func playAudio(named fileName: String, volume: Float = 1.0, completion: @escaping () -> Void) {
        let audioSource = SCNAudioSource(named: fileName)!
        audioSource.load()
        audioSource.volume = volume
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        
        // Run the sound action on the root node
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
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
