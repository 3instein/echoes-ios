//  Scene2.swift

import SceneKit
import UIKit

protocol Scene2Delegate: AnyObject {
    func transitionToScene4()
}

class Scene2: SCNScene {
    weak var delegate: Scene2Delegate?
    
    var playerEntity: PlayerEntity!
    var doorEntity: NPCEntity?
    var grandmaEntity: NPCEntity?
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var cameraComponent: CameraComponent!
    var doorNode: SCNNode?
    var grandmaNode: SCNNode?
    var scnView: SCNView?
    var isDoorOpen = false
    var isCutscenePlaying = false
    
    lazy var doorOpenSound: SCNAudioSource? = loadAudio(named: "door_open.MP3")
    lazy var doorCloseSound: SCNAudioSource? = loadAudio(named: "door_close.MP3")
    lazy var grandmaGreetingsSound: SCNAudioSource? = loadAudio(named: "scene3_grandma_greetings.mp3")
    lazy var andraGreetingsSound: SCNAudioSource? = loadAudio(named: "scene3_andra_greetings.mp3")
    
    private let doorOpenDuration: TimeInterval = 2.5
    private let grandmaMovePosition = SCNVector3(x: 0, y: -9.575, z: 0)
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        guard let combinedScene = SCNScene(named: "scene2.scn") else {
            print("Warning: Scene named 'scene2.scn' not found")
            return
        }
        
        // Add all nodes from the combined scene to rootNode
        for childNode in combinedScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        setupSceneComponents()
        attachAmbientSounds()
    }
    
    private func loadAudio(named fileName: String) -> SCNAudioSource? {
        guard let audioSource = SCNAudioSource(fileNamed: fileName) else {
            print("Error loading audio file: \(fileName)")
            return nil
        }
        audioSource.shouldStream = false
        audioSource.loops = false
        audioSource.volume = 1.0
        audioSource.load()
        return audioSource
    }
    
    func setupSceneComponents() {
        doorNode = rootNode.childNode(withName: "Door", recursively: true)
        grandmaNode = rootNode.childNode(withName: "Grandma", recursively: true)
        
        // Initialize PlayerEntity and its movement component
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node not found in the scene model")
            return
        }
        
        // Attach the existing camera node from the player model to the scene
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
        }
        
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.automaticallyAdjustsZRange = false
        
        // Camera component to handle the camera logic
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        cameraComponent.lockCamera()
        rootNode.addChildNode(lightNode)
        
        // Set up echolocation components for Grandma and Door
        setupNPCEntities()
    }
    
    func setupNPCEntities() {
        if let doorNode = doorNode {
            doorEntity = NPCEntity(npcNode: doorNode, lightNode: lightNode)
        }
        
        if let grandmaNode = grandmaNode {
            grandmaEntity = NPCEntity(npcNode: grandmaNode, lightNode: lightNode)
        }
    }
    
    func activateEcholocation() {
        doorEntity?.activateEcholocation()
        grandmaEntity?.activateEcholocation()
    }
    
    func attachAmbientSounds() {
        attachAmbientAudio(named: "wind.wav", to: "wind", volume: 0.5)
        attachAmbientAudio(named: "crow.wav", to: "crow", volume: 0.5)
        attachAmbientAudio(named: "outsideRain.wav", to: "outsideRain", volume: 0.5)
    }
    
    private func attachAmbientAudio(named fileName: String, to nodeName: String, volume: Float) {
        guard let node = rootNode.childNode(withName: nodeName, recursively: true) else {
            print("Warning: Node '\(nodeName)' not found in the scene model")
            return
        }
        attachAudio(to: node, audioFileName: fileName, volume: volume)
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
    
    func startWalkingToHouse() {
        // Player walks to the front door
        playerEntity.movementComponent.movePlayer(to: SCNVector3(x: -15.388, y: -30.067, z: 0.728), duration: 20.0) {
            self.beginDoorAndGrandmaSequence()
        }
    }
    
    func beginDoorAndGrandmaSequence() {
        isCutscenePlaying = true
        // Activate echolocation for Grandma and Door during cutscene
        activateEcholocation()
        
        let delayAction = SCNAction.wait(duration: 1.5)
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
        guard let doorNode = doorNode, let doorOpenSound = doorOpenSound else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.doorEntity?.activateEcholocation()
        }
        
        let openDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: doorOpenDuration)
        openDoorAction.timingMode = .easeInEaseOut
        let playSoundAction = SCNAction.playAudio(doorOpenSound, waitForCompletion: false)
        let doorSequence = SCNAction.group([openDoorAction, playSoundAction])
        
        doorNode.runAction(doorSequence) {
            completion()
        }
    }
    
    func moveGrandma(completion: @escaping () -> Void) {
        guard let grandmaNode = grandmaNode else { return }
        
        grandmaEntity?.activateEcholocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.grandmaEntity?.activateEcholocation()
        }
        
        // Move grandma to the target position
        let moveAction = SCNAction.move(to: grandmaMovePosition, duration: 2.0)
        
        grandmaNode.runAction(moveAction) {
            completion()
        }
    }
    
    func playDialogueSequence(_ dialogues: [(SCNAudioSource, Float)], completion: @escaping () -> Void) {
        guard !dialogues.isEmpty else {
            completion()
            return
        }
        var remainingDialogues = dialogues
        let (currentSound, volume) = remainingDialogues.removeFirst()
        playAudioSource(currentSound, volume: volume) {
            self.playDialogueSequence(remainingDialogues, completion: completion)
        }
    }
    
    func playDialogues() {
        guard let andraGreetingsSound = andraGreetingsSound, let grandmaGreetingsSound = grandmaGreetingsSound else {
            print("Error: Dialogue audio files not loaded properly")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            // Create a temporary light node with a bluish tint for the dialogue sequence
            let temporaryLightNode = SCNNode()
            let temporaryLight = SCNLight()
            temporaryLight.type = .omni
            temporaryLight.intensity = 7500
            temporaryLight.color = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
            temporaryLightNode.light = temporaryLight
            
            // Position above the player and grandma
            temporaryLightNode.position = SCNVector3(x: 0, y: -18, z: 10)
            self?.rootNode.addChildNode(temporaryLightNode)
        }
        
        let delayBetweenDialogues: TimeInterval = 1.0
        playDialogueSequence([(andraGreetingsSound, 5.0)], completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenDialogues) {
                self.playDialogueSequence([(grandmaGreetingsSound, 8.0)], completion: {
                    self.playDoorCloseSoundAndFadeToBlack()
                })
            }
        })
    }
    
    func playAudioSource(_ audioSource: SCNAudioSource?, volume: Float, completion: @escaping () -> Void) {
        guard let audioSource = audioSource else {
            completion()
            return
        }
        audioSource.volume = volume
        audioSource.isPositional = false
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        rootNode.runAction(playAudioAction) {
            completion()
        }
    }
    
    func playDoorCloseSoundAndFadeToBlack() {
        guard let scnView = scnView, let doorCloseSound = doorCloseSound else { return }
        
        let playSoundAction = SCNAction.playAudio(doorCloseSound, waitForCompletion: false)
        let fadeToBlackAction = SCNAction.run { [weak self] _ in
            self?.fadeScreenToBlack()
        }
        
        let groupAction = SCNAction.group([playSoundAction, fadeToBlackAction])
        rootNode.runAction(groupAction) { [weak self] in
            print("Scene 2 ended")
            // Notify GameViewController to load Scene4
            self?.delegate?.transitionToScene4()
        }
    }
    
    func fadeScreenToBlack() {
        guard let scnView = scnView else { return }
        
        DispatchQueue.main.async {
            let blackOverlay = UIView(frame: scnView.bounds)
            blackOverlay.backgroundColor = .black
            blackOverlay.alpha = 0
            scnView.addSubview(blackOverlay)
            
            UIView.animate(withDuration: 2.0, animations: {
                blackOverlay.alpha = 1.0
            }, completion: { _ in
                blackOverlay.removeFromSuperview() // Remove overlay after fade
                print("Fade to black complete")
            })
        }
    }
    
    func setupGestureRecognizers(for view: SCNView) {
        guard scnView == nil, let cameraComponent = cameraComponent else { return }
        self.scnView = view
        view.isPlaying = true
        view.scene?.isPaused = false
        
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
