//  PlayerEntity.swift

import GameplayKit
import SceneKit

class PlayerEntity: GKEntity {
    var movementComponent: MovementComponent!
    var echolocationComponent: EcholocationComponent?
    var playerNode: SCNNode?
    
    init(in houseRootNode: SCNNode, cameraNode: SCNNode?, lightNode: SCNNode) {
        super.init()
        
        // Locate the player model from the already loaded house scene
        guard let playerNode = houseRootNode.childNode(withName: "player", recursively: true) else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }
        
        self.playerNode = playerNode
        
        // Initialize the movement component
        movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        addComponent(movementComponent)
        
        // Initialize the echolocation component for the player
        echolocationComponent = EcholocationComponent(lightNode: lightNode)
        addComponent(echolocationComponent!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
