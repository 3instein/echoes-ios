import GameplayKit

class MovementComponent: GKAgent3D {
    override init() {
        super.init()
        // Set some movement properties, like speed
        self.maxSpeed = 5.0
        self.maxAcceleration = 10.0
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
