//  Scene4.swift

import SceneKit
import UIKit

class Scene4: SCNScene, SCNPhysicsContactDelegate {
    // MARK: - Properties
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var combinedPieces: [UIView: [UIView]] = [:]
    var completedCombinations: [[UIView]] = []
    var playButton: UIButton?
    
    weak var scnView: SCNView?
    var isGameCompleted: Bool = false
    
    let snapDistance: CGFloat = 50.0
    let transitionTriggerPosition = SCNVector3(-377.69, -463, -1.377)
    let triggerDistance: Float = 80.0
    
    // MARK: - Initialization
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        loadScene()
        setupPlayerEntity()
        setupCamera()
        addBlueFireAnimationNode()
        attachAmbientAudio()
        
        self.physicsWorld.contactDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Scene Setup
    private func loadScene() {
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene4ely.scn") else {
            fatalError("Scene named 'scene4ely.scn' not found.")
        }
        
        // Add all nodes from the house scene to the root node
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
    }
    
    private func setupPlayerEntity() {
        // Create a new player entity using the house scene's root node
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }
        
        // Add player node to the GameScene's rootNode
        rootNode.addChildNode(playerNode)
    }
    
    private func setupCamera() {
        // Attach the existing camera node from the player model to the scene
        guard let playerNode = playerEntity.playerNode else { return }
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
        }
        
        // Configure the camera
        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = false
        
        // Add the camera component to handle the camera logic
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
    }
    
    private func addBlueFireAnimationNode() {
        // Create the fire particle system
        guard let fireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil) else { return }
        
        // Create a new SCNNode for the fire effect
        let fireNode = SCNNode()
        fireNode.position = transitionTriggerPosition
        
        // Attach the particle system to the fire node
        fireNode.addParticleSystem(fireParticleSystem)
        
        scnView?.antialiasingMode = .multisampling4X // Apply anti-aliasing for smoother visuals
        
        // Add the fire node to the scene
        rootNode.addChildNode(fireNode)
    }
    
    // MARK: - Audio Setup
    private func attachAmbientAudio() {
        // List of ambient sounds and their corresponding nodes
        let ambientAudio: [(String, String, Float)] = [
            ("woodenFloor.wav", "woodenFloor", 0.7),
            ("clockTicking.wav", "clockTicking", 0.7),
            ("muffledRain.wav", "muffledRain", 1.0)
        ]
        
        for (fileName, nodeName, volume) in ambientAudio {
            if let node = rootNode.childNode(withName: nodeName, recursively: true) {
                let audioSource = AudioHelper.loadAudio(named: fileName, shouldLoop: fileName == "muffledRain.wav", volume: volume)
                AudioHelper.attachAudio(to: node, audioSource: audioSource)
            } else {
                print("Warning: Node '\(nodeName)' not found for audio file '\(fileName)'")
            }
        }
        
        // Attach specific character dialogues
        attachCharacterAudio()
    }
    
    private func attachCharacterAudio() {
        if let andraParentNode = rootNode.childNode(withName: "player", recursively: true),
           let andraNode = andraParentNode.childNode(withName: "s4-andra", recursively: false) {
            let andraAudio = AudioHelper.loadAudio(named: "s4-andra.wav", volume: 300)
            AudioHelper.attachAudio(to: andraNode, audioSource: andraAudio, volume: 300)
        }
        
        if let grandmaParentNode = rootNode.childNode(withName: "grandma", recursively: true) {
            if let grandmaNode1 = grandmaParentNode.childNode(withName: "s4-grandma1", recursively: false) {
                let grandmaAudio1 = AudioHelper.loadAudio(named: "s4-grandma1.wav", volume: 2)
                AudioHelper.attachAudio(to: grandmaNode1, audioSource: grandmaAudio1)
            }
            
            if let grandmaNode2 = grandmaParentNode.childNode(withName: "s4-grandma2", recursively: false) {
                let grandmaAudio2 = AudioHelper.loadAudio(named: "s4-grandma2.wav", volume: 1000)
                AudioHelper.attachAudio(to: grandmaNode2, audioSource: grandmaAudio2)
            }
        }
    }
    
    // MARK: - Game Logic
    func checkProximityToTransition() -> Bool {
        guard let playerPosition = playerEntity.playerNode?.position else { return false }
        let distance = playerPosition.distance(to: transitionTriggerPosition)
        return distance < triggerDistance
    }
    
    // MARK: - Gesture Recognizers
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
}
