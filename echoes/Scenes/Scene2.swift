//
//  Scene2.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 17/10/24.
//

import SceneKit
import UIKit

class Scene2: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!

    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode

        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene2.scn") else {
            print("Warning: House scene 'Scene2.scn' not found")
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
        cameraNode.camera?.automaticallyAdjustsZRange = true

        // Add the camera component to handle the camera logic
        cameraComponent = CameraComponent(cameraNode: cameraNode)

//        // Add a default light to the scene
//        let lightNode = SCNNode()
//        let light = SCNLight()
//        light.type = .omni
//        light.intensity = 1000
//        lightNode.light = light
//        lightNode.position = SCNVector3(x: 0, y: 20, z: 20)
//        rootNode.addChildNode(lightNode)
//
        // Add an ambient light to the scene
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 300
        ambientLight.color = UIColor.white
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)
        
        rootNode.addChildNode(lightNode)
        
//        if let boxNode = rootNode.childNode(withName: "box", recursively: true) {
//            attachAudio(to: boxNode, audioFileName: "swanlake.wav", volume: 0.5)
//            addBoxVisualization(to: boxNode)
//        }

        if let thunderNode = rootNode.childNode(withName: "wind", recursively: true) {
            attachAudio(to: thunderNode, audioFileName: "wind.wav", volume: 0.5)
        }
        
        if let crowNode = rootNode.childNode(withName: "crow", recursively: true) {
            attachAudio(to: crowNode, audioFileName: "crow.wav", volume: 0.5)
        }
        
        if let lightRainNode = rootNode.childNode(withName: "outsideRain", recursively: true) {
            attachAudio(to: lightRainNode, audioFileName: "outsideRain.wav", volume: 1.0)
        }
        
        //playerEntity.movementComponent.movePlayer(to: SCNVector3(-15.538, -29.942, 0.728), duration: 20.0)
        
        self.background.contents = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    
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
    
    func addBoxVisualization(to node: SCNNode) {
        // Create a box geometry
        let boxGeometry = SCNBox(width: 100, height: 100, length: 100, chamferRadius: 0)

        // Create a material for the box
        let boxMaterial = SCNMaterial()
        boxMaterial.diffuse.contents = UIColor.red // Set the color of the box to red
        boxGeometry.materials = [boxMaterial]

        // Create a node with the box geometry
        let boxNode = SCNNode(geometry: boxGeometry)
        
        // Position the box in the scene
        boxNode.position = SCNVector3(0, 0.5, 0) // Adjust position so the box sits above ground level

        // Add the box node as a child of the given node (the "box" node)
        node.addChildNode(boxNode)
    }

    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
