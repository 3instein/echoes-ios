//
//  Scene6.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 21/10/24.
//

import SceneKit
import UIKit

class Scene8: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    
    weak var scnView: SCNView?
    var playButton: UIButton?  // Store a reference to the play button
    var clueCabinetNode: SCNNode!
    var cluePipeNode: SCNNode!

    var hasKey = true  // Track if the player has the key
    var isCabinetOpened = false  // Track if the player has the key
    var isPlayingPipe = false  // Track if the player has the key

    let proximityDistance: Float = 180.0  // Define a proximity distance
    
    var transitionTriggerPosition = SCNVector3(2602, 559, 45)
    var triggerDistance: Float = 100

    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()

        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene8.scn") else {
            print("Warning: House scene 'Scene 8.scn' not found")
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
        
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 1.0, delay: 0)
        }
        
        if let andraParentNode = rootNode.childNode(withName: "player", recursively: true) {
            if let andraNode = andraParentNode.childNode(withName: "s8-andra1", recursively: false) {
                attachAudio(to: andraNode, audioFileName: "s8-andra1.mp3", volume: 500, delay: 5)
            }
        }
        
        if let pipeNode = rootNode.childNode(withName: "pipe", recursively: true) {
            attachAudio(to: pipeNode, audioFileName: "pipeNecklace.mp3", volume: 0.3, delay: 2)
        }
        
        clueCabinetNode = rootNode.childNode(withName: "smallCabinet", recursively: true)
        
        cluePipeNode = rootNode.childNode(withName: "pipe", recursively: true)
        
        self.physicsWorld.contactDelegate = self
    }
    
    func updateProximityAndGlow(interactButton: UIButton) {
        guard let playerNode = playerEntity.playerNode else {
            print("Error: Player node not found")
            return
        }

        // Measure distances to each clue object
        let distanceToCabinet = playerNode.position.distance(to: clueCabinetNode.position)
        let distanceToPipe = playerNode.position.distance(to: cluePipeNode.position)

        // Determine which object is closer and within the proximity distance
        if distanceToCabinet < proximityDistance && distanceToCabinet < distanceToPipe {
            // If the cabinet is closer
            toggleGlowEffect(on: clueCabinetNode, isEnabled: true)
            toggleGlowEffect(on: cluePipeNode, isEnabled: false)
            
            // Update interact button content
            interactButton.setTitle("Open Cabinet", for: .normal)
            interactButton.isHidden = false
            
            interactButton.removeTarget(nil, action: nil, for: .allEvents)
            interactButton.addTarget(self, action: #selector(openCabinet), for: .touchUpInside)
            
        } else if distanceToPipe < proximityDistance {
            // If the pipe is closer
            toggleGlowEffect(on: cluePipeNode, isEnabled: true)
            toggleGlowEffect(on: clueCabinetNode, isEnabled: false)
            
            // Update interact button content
            interactButton.setTitle("Examine Pipe", for: .normal)
            interactButton.isHidden = false
            
            interactButton.removeTarget(nil, action: nil, for: .allEvents)
            interactButton.addTarget(self, action: #selector(examinePipe), for: .touchUpInside)
        } else {
            // If neither is within proximity, turn off all glows and hide the button
            toggleGlowEffect(on: clueCabinetNode, isEnabled: false)
            toggleGlowEffect(on: cluePipeNode, isEnabled: false)
            interactButton.isHidden = true
        }
    }

    func toggleGlowEffect(on node: SCNNode, isEnabled: Bool) {
        if isEnabled {
            node.categoryBitMask = 2 // Enable glow effect for the specified node
        } else {
            node.categoryBitMask = 1 // Disable glow effect for the specified node
        }
    }

    @objc func openCabinet() {
        // Your existing code for opening the cabinet
        isCabinetOpened = true
        addOpenCabinetSound()
        clueCabinetNode.isHidden = true
        
        attachAudio(to: playerEntity.playerNode!, audioFileName: "s8-andra2.mp3", volume: 400, delay: 3)
    }

    @objc func examinePipe() {
        // Your existing code for examining the pipe
        isPlayingPipe = true
        cluePipeNode.isHidden = true
//        if let pipeNode = rootNode.childNode(withName: "pipe", recursively: true) {
//            // Set the category bitmask for post-processing
//            pipeNode.isHidden = true
//        }
    }

    func addOpenCabinetSound() {
        // Find the cup node
        guard let cabinetNode = rootNode.childNode(withName: "smallCabinet", recursively: true) else {
            print("Warning: Cup node not found")
            return
        }
        
        // Load the sound effect
        let audioSource = SCNAudioSource(fileNamed: "toiletOpenCabinet.mp3")!
        audioSource.load()
        audioSource.volume = 400.0 // Set the volume as needed
        
        let playSound = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the actions sequentially
        cabinetNode.runAction(SCNAction.sequence([playSound]))
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
        
        // Set looping for continuous rain sound
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true  // This ensures the rain loops without breaking
        }
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        let waitAction = SCNAction.wait(duration: delay)
        
        let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
        node.runAction(sequenceAction)
    }
    
    // Check if the player is close to the transition trigger point
    func checkProximityToTransition() -> Bool {
        guard let playerPosition = playerEntity.playerNode?.position else { return false }
        let distance = playerPosition.distance(to: transitionTriggerPosition)
        print("player:", playerPosition)
        print("distance:", distance)
        return distance < triggerDistance
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}

