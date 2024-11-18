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
    var npcEntities: [String: NPCEntity] = [:]
    var scnView: SCNView?
    var lightNode: SCNNode!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var grassFootstepAudioPlayer: AVAudioPlayer?
    var woodFootstepAudioPlayer: AVAudioPlayer?
    var isCutscenePlaying = false
    
    private let animationDelays: [String: TimeInterval] = [
        "doorOpen": 2.5,
        "dialogueDelay": 0.5,
        "cutsceneDelay": 1.5
    ]
    
    lazy var doorOpenSound = AudioHelper.loadAudio(named: "doorOpen.MP3")
    lazy var doorCloseSound = AudioHelper.loadAudio(named: "doorClose.MP3")
    lazy var andraGreetingsSound = AudioHelper.loadAudio(named: "s3-andra.mp3")
    lazy var grandmaGreetingsSound = AudioHelper.loadAudio(named: "s3-grandma.mp3")
    
    // MARK: - Initialization
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        guard let combinedScene = SCNScene(named: "scene2.scn") else {
            fatalError("Scene named 'scene2.scn' not found.")
        }
        
        // Add all nodes from the combined scene to rootNode
        for childNode in combinedScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        setupSceneComponents()
        attachAmbientSounds()
        
        // Prepare Scene5and6 assets and audio
        prepareScene5and6Assets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Scene Setup
    func setupSceneComponents() {
        setupPlayerEntity()
        setupCamera()
        setupNPCEntities()
    }
    
    private func setupPlayerEntity() {
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        guard let playerNode = playerEntity.playerNode else {
            fatalError("Player node not found in the scene model.")
        }
        rootNode.addChildNode(lightNode)
    }
    
    private func setupCamera() {
        guard let playerNode = playerEntity.playerNode else { return }
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        guard let cameraNode = cameraNode else {
            fatalError("Camera node not found in Player model.")
        }
        
        cameraNode.camera?.fieldOfView = 60
        cameraNode.camera?.automaticallyAdjustsZRange = false
        
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        cameraComponent.lockCamera()
    }
    
    func setupNPCEntities() {
        let npcs = ["Door", "Grandma"]
        for npcName in npcs {
            if let node = rootNode.childNode(withName: npcName, recursively: true) {
                npcEntities[npcName] = NPCEntity(npcNode: node, lightNode: lightNode)
            } else {
                print("Warning: NPC node '\(npcName)' not found.")
            }
        }
    }
    
    func attachAmbientSounds() {
        let ambientSounds = [
            ("wind.wav", "wind"),
            ("crow.wav", "crow"),
            ("outsideRain.wav", "outsideRain")
        ]
        
        for (fileName, nodeName) in ambientSounds {
            guard let node = rootNode.childNode(withName: nodeName, recursively: true) else {
                print("Warning: Node '\(nodeName)' not found for ambient sound.")
                continue
            }
            AudioHelper.attachAudio(to: node, audioSource: AudioHelper.loadAudio(named: fileName, shouldLoop: true, volume: 0.1))
        }
    }
    
    // MARK: - Asset Preparation
    func prepareScene5and6Assets() {
        AssetPreloader.preloadScenes5and6 { success in
            if success {
                print("Scene5and6 assets and audio preloaded successfully.")
            } else {
                print("Failed to preload Scene5and6 assets or audio.")
            }
        }
    }
    
    // MARK: - Gameplay Logic
    func startWalkingToHouse() {
        let firstPosition = SCNVector3(x: -15.441, y: -30.882, z: 0.253)
        let secondPosition = SCNVector3(x: -15.388, y: -30.067, z: 0.728)
        
        // Play grass footsteps and move to the first position
        grassFootstepAudioPlayer = playFootstepAudio(named: "grassFootsteps.wav")
        playerEntity.movementComponent.movePlayer(to: firstPosition, duration: 18.0) { [weak self] in
            self?.stopFootstepAudio(player: &self!.grassFootstepAudioPlayer)
            self?.woodFootstepAudioPlayer = self?.playFootstepAudio(named: "woodFootsteps.wav")
            self?.playerEntity.movementComponent.movePlayer(to: secondPosition, duration: 6.0) {
                self?.stopFootstepAudio(player: &self!.woodFootstepAudioPlayer)
                self?.beginDoorAndGrandmaSequence()
            }
        }
    }
    
    func beginDoorAndGrandmaSequence() {
        isCutscenePlaying = true
        activateEcholocation()
        
        let delayAction = SCNAction.wait(duration: animationDelays["cutsceneDelay"]!)
        let sequence = SCNAction.sequence([delayAction, SCNAction.run { [weak self] _ in
            self?.openDoor {
                self?.moveGrandma {
                    self?.playDialogues()
                }
            }
        }])
        rootNode.runAction(sequence)
    }
    
    func activateEcholocation() {
        for npc in npcEntities.values {
            npc.activateEcholocation()
        }
    }
    
    // MARK: - Cutscene Actions
    func openDoor(completion: @escaping () -> Void) {
        guard let doorNode = npcEntities["Door"]?.npcNode else { return }
        AudioHelper.attachAudio(to: doorNode, audioSource: doorOpenSound)
        
        let openDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: animationDelays["doorOpen"]!)
        doorNode.runAction(openDoorAction, completionHandler: completion)
    }
    
    func moveGrandma(completion: @escaping () -> Void) {
        guard let grandmaNode = npcEntities["Grandma"]?.npcNode else { return }
        grandmaNode.runAction(SCNAction.move(to: SCNVector3(x: 0, y: -9.575, z: 0), duration: 2.0), completionHandler: completion)
    }
    
    func playDialogues() {
        let dialogues: [(SCNAudioSource?, Float)] = [
            (andraGreetingsSound, 3.0),
            (grandmaGreetingsSound, 6.0)
        ]
        playDialogueSequence(dialogues) {
            self.playDoorCloseSoundAndFadeToBlack()
        }
    }
    
    func playDialogueSequence(_ dialogues: [(SCNAudioSource?, Float)], completion: @escaping () -> Void) {
        guard !dialogues.isEmpty else {
            completion()
            return
        }
        var remainingDialogues = dialogues
        let (currentSound, volume) = remainingDialogues.removeFirst()
        AudioHelper.attachAudio(to: rootNode, audioSource: currentSound, volume: volume)
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDelays["dialogueDelay"]!) {
            self.playDialogueSequence(remainingDialogues, completion: completion)
        }
    }
    
    func playDoorCloseSoundAndFadeToBlack() {
        guard let doorCloseSound = doorCloseSound else { return }
        AudioHelper.attachAudio(to: rootNode, audioSource: doorCloseSound)
        fadeScreenToBlack { [weak self] in
            self?.delegate?.transitionToScene4()
        }
    }
    
    func fadeScreenToBlack(completion: @escaping () -> Void) {
        guard let scnView = scnView else { return }
        DispatchQueue.main.async {
            let blackOverlay = UIView(frame: scnView.bounds)
            blackOverlay.backgroundColor = .black
            blackOverlay.alpha = 0
            scnView.addSubview(blackOverlay)
            UIView.animate(withDuration: 2.0, animations: {
                blackOverlay.alpha = 1.0
            }, completion: { _ in
                blackOverlay.removeFromSuperview()
                completion()
            })
        }
    }
    
    // MARK: - Audio Management
    func playFootstepAudio(named fileName: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("Audio file \(fileName) not found.")
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1 // Loop indefinitely until stopped
            player.volume = 3.0
            player.play()
            return player
        } catch {
            print("Error initializing audio player for \(fileName): \(error)")
            return nil
        }
    }
    
    func stopFootstepAudio(player: inout AVAudioPlayer?) {
        player?.stop()
        player = nil
    }
    
    // MARK: - Gesture Recognizers
    func setupGestureRecognizers(for view: SCNView) {
        guard scnView == nil, let cameraComponent = cameraComponent else { return }
        self.scnView = view
        cameraComponent.setupGestureRecognizers(for: view)
    }
}
