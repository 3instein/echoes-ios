//
//  Scene6.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 21/10/24.
//

import SceneKit
import UIKit

class Scene5: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    
    weak var scnView: SCNView?
    var playButton: UIButton?  // Store a reference to the play button
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene5.scn") else {
            print("Warning: House scene 'Scene 5.scn' not found")
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
        
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
        
        if let woodNode = rootNode.childNode(withName: "woodenFloor", recursively: false) {
            attachAudio(to: woodNode, audioFileName: "woodenFloor.wav", volume: 0.7, delay: 0)
        }
        
        if let clockNode = rootNode.childNode(withName: "clockTicking", recursively: true) {
            attachAudio(to: clockNode, audioFileName: "clockTicking.wav", volume: 0.7, delay: 0)
        }
        
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 0.7, delay: 0)
        }
        
        if let andraParentNode = rootNode.childNode(withName: "player", recursively: true) {
            if let andraNode = andraParentNode.childNode(withName: "s5-andra", recursively: false) {
                attachAudio(to: andraNode, audioFileName: "s5-andra.wav", volume: 100, delay: 15)
            }
        }

        if let grandmaParentNode = rootNode.childNode(withName: "grandma", recursively: true) {
            if let grandmaNode1 = grandmaParentNode.childNode(withName: "s5-grandma", recursively: false) {
                attachAudio(to: grandmaNode1, audioFileName: "s5-grandma.wav", volume: 20, delay: 3)
            }
        }
        
//        if let andraNode = rootNode.childNode(withName: "s5-andra", recursively: false) {
//            attachAudio(to: andraNode, audioFileName: "s5-andra.wav", volume: 100, delay: 15)
//        }
//        
//        if let grandmaNode = rootNode.childNode(withName: "s5-grandma", recursively: false) {
//            attachAudio(to: grandmaNode, audioFileName: "s5-grandma.wav", volume: 210, delay: 3)
//        }
        
//        let ambientLightNode = SCNNode()
//        let ambientLight = SCNLight()
//        ambientLight.type = .ambient
//        ambientLight.intensity = 500
//        ambientLight.color = UIColor.white
//        ambientLightNode.light = ambientLight
//        rootNode.addChildNode(ambientLightNode)
        
        // Initialize MovementComponent with lightNode reference
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
                
        self.physicsWorld.contactDelegate = self
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }

        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume

        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
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

// SCNVector3 extension to calculate the distance between two points
extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
}
