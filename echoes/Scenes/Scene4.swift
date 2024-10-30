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
    
    let transitionTriggerPosition = SCNVector3(62.983, 98.335, 29.035)
    let triggerDistance: Float = 100.0
    
    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene4.scn") else {
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
//        cameraNode.camera?.fieldOfView = 75
//        cameraNode.camera?.automaticallyAdjustsZRange = false
        
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
                attachAudio(to: grandmaNode2, audioFileName: "s4-grandma2.wav", volume: 200, delay: 14)
            }
        }
        
        //        let ambientLightNode = SCNNode()
        //        let ambientLight = SCNLight()
        //        ambientLight.type = .ambient
        //        ambientLight.intensity = 500
        //        ambientLight.color = UIColor.blue
        //        ambientLightNode.light = ambientLight
        //        rootNode.addChildNode(ambientLightNode)
        
        self.physicsWorld.contactDelegate = self
        addCandleLightEffects(around: playerNode)
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
    
    func addCandleLightEffects(around node: SCNNode) {
        // Updated candle positions to create a larger, circular arrangement around the player
        let candlePositions = [
            SCNVector3(x: 1.0, y: 0, z: 1.0),
            SCNVector3(x: -1.0, y: 0, z: 1.0),
            SCNVector3(x: 1.0, y: 0, z: -1.0),
            SCNVector3(x: -1.0, y: 0, z: -1.0)
        ]
        
        for position in candlePositions {
            let candleNode = SCNNode()
            candleNode.position = position

            // Create a candle cylinder geometry for a realistic candle appearance
            let candleGeometry = SCNCylinder(radius: 0.07, height: 0.3)
            candleGeometry.firstMaterial?.diffuse.contents = UIColor.white
            let candleVisualNode = SCNNode(geometry: candleGeometry)
            candleVisualNode.position = SCNVector3(0, 0.15, 0)
            candleNode.addChildNode(candleVisualNode)
            
            // Add a small flame on top of the candle using a sphere
            let flameGeometry = SCNSphere(radius: 0.02)
            flameGeometry.firstMaterial?.diffuse.contents = UIColor.orange
            let flameNode = SCNNode(geometry: flameGeometry)
            flameNode.position = SCNVector3(0, 0.3, 0) // Position at the top of the candle
            candleNode.addChildNode(flameNode)
            
            // Candlelight setup with a flickering effect
            let candleLight = SCNLight()
            candleLight.type = .omni
            candleLight.intensity = 600
            candleLight.color = UIColor.orange
            candleNode.light = candleLight
            
            node.addChildNode(candleNode)
            
            // Flickering effect with slight intensity changes to mimic realistic candlelight
            let flickerAction = SCNAction.sequence([
                SCNAction.customAction(duration: 0.1) { _,_ in candleLight.intensity = 550 },
                SCNAction.wait(duration: 0.05),
                SCNAction.customAction(duration: 0.1) { _,_ in candleLight.intensity = 620 },
                SCNAction.wait(duration: 0.05),
                SCNAction.customAction(duration: 0.1) { _,_ in candleLight.intensity = 600 }
            ])
            let repeatFlicker = SCNAction.repeatForever(flickerAction)
            candleNode.runAction(repeatFlicker)
        }
    }



    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
