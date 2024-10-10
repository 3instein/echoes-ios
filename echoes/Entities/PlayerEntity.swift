// PlayerEntity.swift

import GameplayKit
import SceneKit

class PlayerEntity: GKEntity {
    var movementComponent: MovementComponent!
    var playerNode: SCNNode?
    
    init(in houseRootNode: SCNNode) {
        super.init()
        
        // Locate the player model from the already loaded house scene
        playerNode = houseRootNode.childNode(withName: "player", recursively: true)
        
        if let playerNode = playerNode {
            
        } else {
            print("Warning: Player node named 'Player' not found in house model")
        }
        
        // Create a movement component to handle player movement
        movementComponent = MovementComponent()
        addComponent(movementComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
