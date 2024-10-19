//  Scene3.swift

import SceneKit
import UIKit

class Scene3: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent?
    var lightNode: SCNNode!
    var doorNode: SCNNode?
    var grandmaNode: SCNNode?
    var scnView: SCNView?
    var isDoorOpen = false
    var isCutscenePlaying = false
    
    // Scene initializer with lightNode as an external dependency
    init(lightNode: SCNNode) {
        super.init()
        
        self.lightNode = lightNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene3.scn") else {
            print("Warning: House scene 'Scene3.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        // Find the door and grandma nodes in the scene
        doorNode = rootNode.childNode(withName: "Door", recursively: true)
        grandmaNode = rootNode.childNode(withName: "Grandma", recursively: true)
        
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
        
        // Initialize cameraComponent with a valid cameraNode
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        // Add the external light node to the scene
        rootNode.addChildNode(lightNode)
        
        // Initialize MovementComponent with lightNode reference
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
        
        // Start the cutscene
        startCutscene()
    }
    
    func startCutscene() {
        isCutscenePlaying = true
        disablePlayerMovement() // Disable movement during cutscene
        
        // Delay before starting the door opening animation
        let delayAction = SCNAction.wait(duration: 0.5)
        
        // Sequence of actions: delay, open door, then move grandma
        let sequence = SCNAction.sequence([delayAction, SCNAction.run { [weak self] _ in
            self?.openDoor {
                self?.moveGrandma()
            }
        }])
        
        rootNode.runAction(sequence)
    }
    
    func disablePlayerMovement() {
        // You can uncomment and implement this depending on your setup
        // playerEntity.movementComponent.isEnabled = false
    }
    
    func enablePlayerMovement() {
        // You can uncomment and implement this depending on your setup
        // playerEntity.movementComponent.isEnabled = true
    }
    
    func openDoor(completion: @escaping () -> Void) {
        guard let doorNode = doorNode else { return }
        
        // Animate the door opening (rotating around the Y-axis)
        let openDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: 2.0)
        doorNode.runAction(openDoorAction) {
            // Call the completion handler once the door has finished opening
            completion()
        }
        isDoorOpen = true
    }
    
    func moveGrandma() {
        guard let grandmaNode = grandmaNode else { return }
        
        // Move the grandma to the specified position with a slight delay
        let targetPosition = SCNVector3(x: 0, y: -10, z: 0)
        let moveAction = SCNAction.move(to: targetPosition, duration: 2.5)
        
        grandmaNode.runAction(moveAction) { [weak self] in
            // Re-enable player movement after cutscene
            self?.enablePlayerMovement()
            self?.isCutscenePlaying = false
        }
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
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
