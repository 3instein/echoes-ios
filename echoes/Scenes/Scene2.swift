//  Scene2.swift

import SceneKit
import UIKit
import AVFoundation

protocol Scene2Delegate: AnyObject {
    func transitionToScene4()
}

class Scene2: SCNScene {
    // MARK: - Properties
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
    var grassFootstepAudioPlayer: AVAudioPlayer?
    var woodFootstepAudioPlayer: AVAudioPlayer?
    var isDoorOpen = false
    var isCutscenePlaying = false
    
    lazy var doorOpenSound: SCNAudioSource? = loadAudio(named: "doorOpen.MP3")
    lazy var doorCloseSound: SCNAudioSource? = loadAudio(named: "doorClose.MP3")
    lazy var grandmaGreetingsSound: SCNAudioSource? = loadAudio(named: "s3-grandma.mp3")
    lazy var andraGreetingsSound: SCNAudioSource? = loadAudio(named: "s3-andra.mp3")
    
    private let doorOpenDuration: TimeInterval = 2.5
    private let grandmaMovePosition = SCNVector3(x: 0, y: -9.575, z: 0)
    
    // MARK: - Initializer
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        guard let combinedScene = SCNScene(named: "scene2.scn") else {
            fatalError("Error: Scene named 'scene2.scn' not found")
        }
        
        // Add all nodes from the combined scene to rootNode
        for childNode in combinedScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        setupSceneComponents()
        attachAmbientSounds()
        prepareScene4Assets()
    }
    
    // MARK: - Asset Preloading
    private func prepareScene4Assets() {
        AssetPreloader.preloadScene4 { success in
            if success {
                print("Scene4 assets successfully prepared.")
            } else {
                print("Error: Failed to prepare Scene4 assets.")
            }
        }
    }
    
    // MARK: - Scene Setup
    private func setupSceneComponents() {
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
    
    private func setupNPCEntities() {
        if let doorNode = doorNode {
            doorEntity = NPCEntity(npcNode: doorNode, lightNode: lightNode)
        }
        
        if let grandmaNode = grandmaNode {
            grandmaEntity = NPCEntity(npcNode: grandmaNode, lightNode: lightNode)
        }
    }
    
    // MARK: - Ambient Audio
    private func attachAmbientSounds() {
        attachAmbientAudio(named: "wind.wav", to: "wind", volume: 0.1)
        attachAmbientAudio(named: "crow.wav", to: "crow", volume: 0.1)
        attachAmbientAudio(named: "outsideRain.wav", to: "outsideRain", volume: 0.1)
    }
    
    private func attachAmbientAudio(named fileName: String, to nodeName: String, volume: Float) {
        guard let node = rootNode.childNode(withName: nodeName, recursively: true) else {
            print("Warning: Node '\(nodeName)' not found in the scene model")
            return
        }
        attachAudio(to: node, audioFileName: fileName, volume: volume)
    }
    
    private func attachAudio(to node: SCNNode, audioFileName: String, volume: Float = 1.0) {
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
    
    // MARK: - Cutscene Handling
    func activateEcholocation() {
        doorEntity?.activateEcholocation()
        grandmaEntity?.activateEcholocation()
    }
    
    func startWalkingToHouse() {
        let firstPosition = SCNVector3(x: -15.441, y: -30.882, z: 0.253)
        let secondPosition = SCNVector3(x: -15.388, y: -30.067, z: 0.728)
        
        // Play grass footsteps and move to the first position
        playFootstepAudio(named: "grassFootsteps.wav", player: &grassFootstepAudioPlayer)
        playerEntity.movementComponent.movePlayer(to: firstPosition, duration: 18.0) { [weak self] in
            // Stop grass footsteps when reaching the first position
            self?.stopFootstepAudio(player: &self!.grassFootstepAudioPlayer)
            
            // Play wood footsteps and move to the second position
            self?.playFootstepAudio(named: "woodFootsteps.wav", player: &self!.woodFootstepAudioPlayer)
            self?.playerEntity.movementComponent.movePlayer(to: secondPosition, duration: 6.0) {
                // Stop wood footsteps when reaching the second position
                self?.stopFootstepAudio(player: &self!.woodFootstepAudioPlayer)
                
                // Start the next sequence after reaching the destination
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.beginDoorAndGrandmaSequence()
                }
            }
        }
    }
    
    private func playFootstepAudio(named fileName: String, player: inout AVAudioPlayer?) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Audio file \(fileName) not found.")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 3.0
            player?.numberOfLoops = -1 // Loop indefinitely until stopped
            player?.play()
        } catch {
            print("Error initializing audio player for \(fileName): \(error)")
        }
    }
    
    private func stopFootstepAudio(player: inout AVAudioPlayer?) {
        player?.stop()
        player = nil
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
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
        
        // Trigger echolocation and play footstep sound
        grandmaEntity?.activateEcholocation()
        
        // Play wood footsteps while grandma is moving
        playFootstepAudio(named: "woodFootsteps.wav", player: &woodFootstepAudioPlayer)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.grandmaEntity?.activateEcholocation()
        }
        
        // Move grandma to the target position
        let moveAction = SCNAction.move(to: grandmaMovePosition, duration: 2.0)
        
        grandmaNode.runAction(moveAction) {
            // Stop wood footsteps when grandma reaches her position
            self.stopFootstepAudio(player: &self.woodFootstepAudioPlayer)
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
            temporaryLight.intensity = 8500
            temporaryLight.color = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0)
            temporaryLightNode.light = temporaryLight
            
            // Position above the player and grandma
            temporaryLightNode.position = SCNVector3(x: 0, y: -18, z: 10)
            self?.rootNode.addChildNode(temporaryLightNode)
        }
        
        let delayBetweenDialogues: TimeInterval = 1.5
        playDialogueSequence([(andraGreetingsSound, 3.0)], completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenDialogues) {
                self.playDialogueSequence([(grandmaGreetingsSound, 6.0)], completion: {
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
            
            UIView.animate(withDuration: 1.0, animations: {
                blackOverlay.alpha = 1.0
            }, completion: { _ in
                blackOverlay.removeFromSuperview()
                print("Fade to black complete")
            })
        }
    }
    
    // MARK: - Gesture Recognizers
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
