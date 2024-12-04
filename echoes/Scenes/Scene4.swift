//  Scene4.swift

import SceneKit
import UIKit

class Scene4: SCNScene, SCNPhysicsContactDelegate {
    // MARK: - Properties
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var combinedPieces: [UIView: [UIView]] = [:] // Dictionary that tracks combined pieces
    var completedCombinations: [[UIView]] = [] // Track completed combinations
    
    weak var scnView: SCNView?
    var playButton: UIButton? // Store a reference to the play button
    
    var isGameCompleted: Bool = false
    let snapDistance: CGFloat = 50.0
    let transitionTriggerPosition = SCNVector3(-377.69, -463, -1.377)
    let triggerDistance: Float = 80.0
    
    // MARK: - Initialization
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
        loadSceneAssets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Asset Loading
    private func loadSceneAssets() {
        guard let houseScene = SCNScene(named: "scene4ely.scn") else {
            fatalError("Error: Scene named 'scene4ely.scn' not found")
        }
        
        // Add nodes to rootNode
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        initializePlayerEntity()
        attachAudioAssets()
        addBlueFireAnimationNode()
    }
    
    // MARK: - Player Setup
    private func initializePlayerEntity() {
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node not found in Scene4 model")
            return
        }
        
        // Add player node and setup camera
        rootNode.addChildNode(playerNode)
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
        }
        
        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = false
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
    }
    
    // MARK: - Audio Setup
    private func attachAudioAssets() {
        attachAudioNode(named: "woodenFloor.wav", to: "woodenFloor", volume: 0.2, delay: 0)
        
        attachAudioNode(named: "muffledRain.wav", to: "muffledRain", volume: 0.2, delay: 0)
        
        attachAudioNode(named: "s4-andra.wav", to: "player", volume: 10000, delay: 32)
        
        attachAudioNode(named: "s4-grandma1.wav", to: "grandma", volume: 10000, delay: 10)

        attachAudioNode(named: "s4-grandma2.wav", to: "grandma", volume: 9000, delay: 25)
    }
    
    private func attachAudioNode(named fileName: String, to nodeName: String, volume: Float, delay: TimeInterval) {
        guard let node = rootNode.childNode(withName: nodeName, recursively: true) else {
            print("Warning: Node '\(nodeName)' not found in the scene model")
            return
        }
        attachAudio(to: node, audioFileName: fileName, volume: volume, delay: delay)
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true
        }

        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.volume = volume

        audioSource.load()
                
        let playAudioAction = SCNAction.sequence([
            SCNAction.wait(duration: delay),
            SCNAction.playAudio(audioSource, waitForCompletion: false)
        ])
        
        node.runAction(playAudioAction)
    }
    
    // MARK: - Scene Effects
    private func addBlueFireAnimationNode() {
        guard let fireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil) else {
            print("Warning: Fire particle system not found")
            return
        }
        
        let fireNode = SCNNode()
        fireNode.position = transitionTriggerPosition
        fireNode.addParticleSystem(fireParticleSystem)
        
        scnView?.antialiasingMode = .multisampling4X // Smoother visuals
        rootNode.addChildNode(fireNode)
    }
    
    // MARK: - Proximity Check
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
