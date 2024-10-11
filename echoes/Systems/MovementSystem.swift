// MovementSystem.swift

import GameplayKit

class MovementSystem: GKComponentSystem<MovementComponent> {
    func updateMovement(deltaTime: TimeInterval) {
        for component in components {
            component.moveForward()
        }
    }
}
