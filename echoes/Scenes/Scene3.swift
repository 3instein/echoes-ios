//  Scene3.swift

import SceneKit
import UIKit

class Scene3: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent?
    var doorNode: SCNNode?
    var scnView: SCNView?
    var isDoorOpen = false
    
    override init() {
        super.init()
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene 3.scn") else {
            print("Warning: House scene 'Scene 3.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        // Find the door node in the scene
        doorNode = rootNode.childNode(withName: "door", recursively: true)
        
        // Create a new player entity and initialize it using the house scene's root node
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }
        
        // Add player node to the GameScene's rootNode
        rootNode.addChildNode(playerNode)
        
        // Attach the existing camera node from the player model to the scene
        cameraNode = playerNode.childNode(withName: "camera", recursively: true)
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
        }
        
        // Initialize cameraComponent with a valid cameraNode
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        // Add a default light to the scene
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1000
        lightNode.light = light
        lightNode.position = SCNVector3(x: 0, y: 20, z: 20)
        rootNode.addChildNode(lightNode)
        
        // Add an ambient light to the scene
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 500
        ambientLight.color = UIColor.white
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)
    }
    
    func setupGestureRecognizers(for view: SCNView) {
        // Save a reference to the SCNView
        self.scnView = view
        
        // Ensure cameraComponent is initialized properly before using it
        guard let cameraComponent = cameraComponent else {
            print("Error: CameraComponent is nil. Cannot set up gesture recognizers.")
            return
        }
        
        // Gesture recognizer for camera control
        cameraComponent.setupGestureRecognizers(for: view)
        
        // Add a tap gesture recognizer for the door
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let scnView = scnView else { return }
        
        // Get the location of the tap
        let location = gestureRecognizer.location(in: scnView)
        
        // Perform the hit test on the SCNView
        let hitResults = scnView.hitTest(location, options: [:])
        
        // Check if the door was tapped and the door hasn't been opened yet
        if let result = hitResults.first(where: { $0.node == doorNode }), !isDoorOpen {
            openDoor()
        }
    }
    
    func openDoor() {
        guard let doorNode = doorNode else { return }
        
        // Animate the door opening (rotating around the Y-axis)
        let openDoorAction = SCNAction.rotateBy(x: 0, y: -.pi / 2, z: 0, duration: 2.0)
        doorNode.runAction(openDoorAction)
        isDoorOpen = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
