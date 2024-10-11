// MovementComponent.swift

import GameplayKit
import SceneKit

class MovementComponent: GKComponent {
    let playerNode: SCNNode
    let speed: Float = 0.5
    
    var joystickComponent: VirtualJoystickComponent?
    
    init(playerNode: SCNNode) {
        self.playerNode = playerNode
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(deltaTime seconds: TimeInterval) {
        guard let joystick = joystickComponent, joystick.isTouching else { return }
        
        let direction = joystick.direction
        let movementVector = SCNVector3(x: Float(direction.x) * speed, y: 0, z: Float(direction.y) * speed)
        playerNode.position = SCNVector3(playerNode.position.x + movementVector.x, playerNode.position.y + movementVector.y, playerNode.position.z + movementVector.z)
    }
}
