// MovementComponent.swift

import GameplayKit
import SceneKit

class MovementComponent: GKComponent {
    let playerNode: SCNNode
    let xSpeed: Float = 60
    let zSpeed: Float = 45
    
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
        let deltaTime = Float(seconds)
        let movementVector = SCNVector3(
            x: -Float(direction.x) * xSpeed * (deltaTime),
            y: 0,
            z: -Float(direction.y) * zSpeed * deltaTime
        )
        playerNode.localTranslate(by: movementVector)
    }
}
