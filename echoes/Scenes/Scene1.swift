import SceneKit
import UIKit

class Scene1: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!

    override init() {
        super.init()
        lightNode = SCNNode()

        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene 1.scn") else {
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

        // Add a default light to the scene
        let light = SCNLight()
        light.type = .omni
        light.intensity = 20
        lightNode.light = light

        // Set the initial position of the lightNode to match the playerNode's position
        lightNode.position = playerNode.position
        rootNode.addChildNode(lightNode)

        // Add an ambient light to the scene
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 20
        ambientLight.color = UIColor.blue
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)

        // Initialize MovementComponent with lightNode reference
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
    }

    // Function to update the light position to follow the player
    func updateLightPosition() {
        guard let playerNode = playerEntity.playerNode else { return }
        lightNode.position = playerNode.position
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
