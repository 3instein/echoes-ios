// GameScene.swift

import SceneKit

class GameScene: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    
    override init() {
        super.init()
        
        if let houseScene = SCNScene(named: "house.scn") {
                    for childNode in houseScene.rootNode.childNodes {
                        rootNode.addChildNode(childNode)
                    }
                }
        
        // Create a new player entity
        playerEntity = PlayerEntity()
        
        if let playerNode = playerEntity.playerNode {
            rootNode.addChildNode(playerNode)
            
            // Attach the existing camera node from the player to the scene
            cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
            if cameraNode != nil {
                // Make optional adjustments to the camera if needed
                cameraNode?.camera?.fieldOfView = 75
                cameraNode?.camera?.automaticallyAdjustsZRange = true
            } else {
                print("Warning: Camera node named 'Camera' not found in Player model")
            }
        } else {
            print("Warning: Player node named 'Player' not found in Player model")
        }
        
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
