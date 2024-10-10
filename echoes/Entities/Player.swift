import GameplayKit

class PlayerEntity: GKEntity {
    // Define properties for the player, such as movement components
    var movementComponent: MovementComponent!
    
    override init() {
        super.init()
        
        // Create movement component to handle player movement
        movementComponent = MovementComponent()
        addComponent(movementComponent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
