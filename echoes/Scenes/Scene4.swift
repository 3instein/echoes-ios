//
//  Scene6.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 21/10/24.
//

import SceneKit
import UIKit

class Scene4: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var combinedPieces: [UIView: [UIView]] = [:]  // Dictionary that tracks combined pieces
    var completedCombinations: [[UIView]] = []  // Track completed combinations
    
    weak var scnView: SCNView?
    var playButton: UIButton?  // Store a reference to the play button
    
    var isGameCompleted: Bool = false  // Track if the game is completed
    let snapDistance: CGFloat = 50.0
    
    let transitionTriggerPosition = SCNVector3(28.603, 494, 103.106)
    let triggerDistance: Float = 80.0
    
    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene4-baru.scn") else {
            print("Warning: House scene 'Scene 4.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
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
        
        // Make optional adjustments to the camera if needed
        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = false
        
        // Add the camera component to handle the camera logic
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
        
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
                attachAudio(to: andraNode, audioFileName: "s4-andra.wav", volume: 300, delay: 23)
            }
        }
        
        if let grandmaParentNode = rootNode.childNode(withName: "grandma", recursively: true) {
            if let grandmaNode1 = grandmaParentNode.childNode(withName: "s4-grandma1", recursively: false) {
                attachAudio(to: grandmaNode1, audioFileName: "s4-grandma1.wav", volume: 3, delay: 3)
            }
            
            if let grandmaNode2 = grandmaParentNode.childNode(withName: "s4-grandma2", recursively: false) {
                attachAudio(to: grandmaNode2, audioFileName: "s4-grandma2.wav", volume: 200, delay: 14.5)
            }
        }
        
        // Create and add blue fire animation node
        addBlueFireAnimationNode()
        
        self.physicsWorld.contactDelegate = self
    }
    
    private func addBlueFireAnimationNode() {
        // Create the fire particle system
        let fireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil)
        
        // Create a new SCNNode for the fire effect
        let fireNode = SCNNode()
        fireNode.position = transitionTriggerPosition
        
        // Attach the particle system to the fire node
        fireNode.addParticleSystem(fireParticleSystem!)
        
        scnView?.antialiasingMode = .multisampling4X // Apply anti-aliasing for smoother visuals

        // Add the fire node to the scene
        rootNode.addChildNode(fireNode)
    }

    // Check if the player is close to the transition trigger point
     func checkProximityToTransition() -> Bool {
         guard let playerPosition = playerEntity.playerNode?.position else { return false }
         let distance = playerPosition.distance(to: transitionTriggerPosition)
         return distance < triggerDistance
     }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        if (audioFileName == "s4-andra.wav"){
            audioSource.isPositional = false
        } else {
            audioSource.isPositional = true
        }
        
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        
        // Set looping for continuous rain sound
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true  // This ensures the rain loops without breaking
        }
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        let waitAction = SCNAction.wait(duration: delay)
        let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
        node.runAction(sequenceAction)
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
