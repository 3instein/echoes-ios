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
        
        loadScene4Assets()
        prepareScene5And6Assets()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Asset Loading
    private func loadScene4Assets() {
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
    
    private func prepareScene5And6Assets() {
        AssetPreloader.preloadScenes5and6 { success in
            if success {
                print("Scene5and6 assets successfully prepared.")
            } else {
                print("Error: Failed to prepare Scene5and6 assets.")
            }
        }
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
        if let woodNode = rootNode.childNode(withName: "woodenFloor", recursively: false) {
            attachAudio(to: woodNode, audioFileName: "woodenFloor.wav", volume: 0.7, delay: 0)
        }
        
        if let clockNode = rootNode.childNode(withName: "clockTicking", recursively: true) {
            attachAudio(to: clockNode, audioFileName: "clockTicking.wav", volume: 0.7, delay: 0)
        }
        
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 1.0, delay: 0)
        }
        
        if let andraParentNode = rootNode.childNode(withName: "player", recursively: true) {
            if let andraNode = andraParentNode.childNode(withName: "s4-andra", recursively: false) {
                attachAudio(to: andraNode, audioFileName: "s4-andra.wav", volume: 300, delay: 30)
            }
        }
        
        if let grandmaParentNode = rootNode.childNode(withName: "grandma", recursively: true) {
            if let grandmaNode1 = grandmaParentNode.childNode(withName: "s4-grandma1", recursively: false) {
                attachAudio(to: grandmaNode1, audioFileName: "s4-grandma1.wav", volume: 2, delay: 10)
            }
            
            if let grandmaNode2 = grandmaParentNode.childNode(withName: "s4-grandma2", recursively: false) {
                attachAudio(to: grandmaNode2, audioFileName: "s4-grandma2.wav", volume: 1000, delay: 22)
            }
        }
    }
    
    private func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        audioSource.isPositional = true
        
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true
        }
        
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
