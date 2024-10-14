import GameplayKit
import SceneKit

class MovementComponent: GKComponent {
    let playerNode: SCNNode
    let movementSpeed: Float = 60
    
    var joystickComponent: VirtualJoystickComponent?
    var cameraNode: SCNNode?

    init(playerNode: SCNNode, cameraNode: SCNNode?) {
        self.playerNode = playerNode
        self.cameraNode = cameraNode
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let joystick = joystickComponent, joystick.isTouching, let cameraNode = cameraNode else { return }

        let direction = joystick.direction
        let deltaTime = Float(seconds)

        // Calculate the camera's forward and right direction vectors
        let cameraTransform = cameraNode.transform
        let forwardVector = SCNVector3(cameraTransform.m31, cameraTransform.m32, cameraTransform.m33) // Reversed direction
        let rightVector = SCNVector3(-cameraTransform.m11, -cameraTransform.m12, -cameraTransform.m13) // Reversed direction

        // Scale direction by joystick input
        let forwardMovement = forwardVector * Float(direction.y) * movementSpeed * deltaTime
        let rightMovement = rightVector * Float(direction.x) * movementSpeed * deltaTime

        // Combine forward and right movement
        let movementVector = forwardMovement + rightMovement

        // Translate the player node based on the movement vector
        playerNode.localTranslate(by: movementVector)
    }
}

// SCNVector3 Operators
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func *(vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}
