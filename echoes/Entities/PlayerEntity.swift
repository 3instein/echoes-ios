// PlayerEntity.swift

import GameplayKit
import SceneKit

class PlayerEntity: GKEntity {
    var movementComponent: MovementComponent!
    var playerNode: SCNNode?

    init(in houseRootNode: SCNNode) {
        super.init()

        // Locate the player model from the already loaded house scene
        guard let playerNode = houseRootNode.childNode(withName: "player", recursively: true) else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }

        self.playerNode = playerNode

        // Create a movement component to handle player movement
        movementComponent = MovementComponent(playerNode: playerNode)
        addComponent(movementComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
