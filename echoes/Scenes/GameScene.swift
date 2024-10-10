import SceneKit

class GameScene: SCNScene {
    var cameraNode: SCNNode!
    
    override init() {
        super.init()
        
        // Load the ship scene from the Scenes folder
        if let houseScene = SCNScene(named: "house.scn") {
            for childNode in houseScene.rootNode.childNodes {
                rootNode.addChildNode(childNode)
            }
        }
        
        // Add a default light to the scene
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .omni
        light.intensity = 1000
        lightNode.light = light
        lightNode.position = SCNVector3(x: 0, y: 20, z: 20)
        rootNode.addChildNode(lightNode)

        // Add an ambient light to the scene
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 500
        ambientLight.color = UIColor.white
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)

        // Add a camera to the scene
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 125, z: 190)
        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = true
        rootNode.addChildNode(cameraNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
