import GameplayKit
import SceneKit

class PlayerEntity: GKEntity {
    var movementComponent: MovementComponent!
    var playerNode: SCNNode?

    init(in houseRootNode: SCNNode, cameraNode: SCNNode?, lightNode: SCNNode) { // Add lightNode as a parameter
        super.init()

        // Locate the player model from the already loaded house scene
        guard let playerNode = houseRootNode.childNode(withName: "player", recursively: true) else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }

        self.playerNode = playerNode

        // Create a movement component to handle player movement, including the light node
        movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode) // Pass lightNode
        addComponent(movementComponent)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
