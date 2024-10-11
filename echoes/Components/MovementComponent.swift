// MovementComponent.swift

import GameplayKit
import SceneKit

class MovementComponent: GKComponent {
    private var node: SCNNode
    private var velocity: Float = 0.5

    init(node: SCNNode) {
        self.node = node
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func moveForward() {
        let moveVector = SCNVector3(x: 0, y: 0, z: velocity)
        let transformedMoveVector = node.simdTransform * simd_float4(moveVector.x, moveVector.y, moveVector.z, 0)
        node.position = SCNVector3(
            x: node.position.x + transformedMoveVector.x,
            y: node.position.y + transformedMoveVector.y,
            z: node.position.z + transformedMoveVector.z
        )
    }
}
