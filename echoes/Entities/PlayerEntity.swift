// PlayerEntity.swift

import GameplayKit
import SceneKit

class PlayerEntity: GKEntity {
    var movementComponent: MovementComponent!
    var playerNode: SCNNode!
    
    override init() {
        super.init()
        
        // Load the player model from the art.scnassets folder
        if let playerScene = SCNScene(named: "art.scnassets/Player.scn") {
            playerNode = playerScene.rootNode.childNode(withName: "Player", recursively: true)
            if let playerNode = playerNode {
                playerNode.position = SCNVector3(x: 0, y: 0, z: 0)
            }
        }
        
        // Create a movement component to handle player movement
        movementComponent = MovementComponent()
        addComponent(movementComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
