import SceneKit
import UIKit

class Scene1: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!
    var combinedPieces: [UIView: [UIView]] = [:]  // Dictionary that tracks combined pieces
    var completedCombinations: [[UIView]] = []  // Track completed combinations

    weak var scnView: SCNView?

    override init() {
        super.init()

        lightNode = SCNNode()

        guard let houseScene = SCNScene(named: "scene1.scn") else {
            print("Warning: House scene 'Scene 1.scn' not found")
            return
        }

        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }

        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)

        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }

        rootNode.addChildNode(playerNode)

        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
        }

        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = true
        cameraComponent = CameraComponent(cameraNode: cameraNode)

        let light = SCNLight()
        light.type = .omni
        light.intensity = 10
        lightNode.light = light

        lightNode.position = playerNode.position
        rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 20
        ambientLight.color = UIColor.blue
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)

        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
    }

    func setupGestureRecognizers(for view: UIView) {
            cameraComponent.setupGestureRecognizers(for: view)
        }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}



