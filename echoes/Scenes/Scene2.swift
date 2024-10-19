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
        guard let houseScene = SCNScene(named: "scene2.scn") else {
            print("Warning: House scene 'Scene 1.scn' not found")
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
        cameraComponent.lockCamera()
        rootNode.addChildNode(lightNode)

        guard let windNode = rootNode.childNode(withName: "wind", recursively: true) else {
            print("Warning: Thunder node named 'wind' not found in house model")
            return
        }

        attachAudio(to: windNode, audioFileName: "wind.wav", volume: 0.5)
        
        guard let crowNode = rootNode.childNode(withName: "crow", recursively: true) else {
            print("Warning: Crow node named 'crow' not found in house model")
            return
        }
        
        attachAudio(to: crowNode, audioFileName: "crow.wav", volume: 0.5)
        
        guard let lightRainNode = rootNode.childNode(withName: "lightRain", recursively: true) else {
            print("Warning: LightRain node named 'lightRain' not found in house model")
            return
        }
        
        attachAudio(to: lightRainNode, audioFileName: "lightRain.wav", volume: 0.5)
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
