//  Scene10.swift

import SceneKit
import UIKit

class Scene10: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        // Load the room model and assets
        guard let roomScene = SCNScene(named: "scene10.scn") else {
            print("Warning: Scene named 'scene10.scn' not found")
            return
        }
        
        // Add room nodes to the scene
        for childNode in roomScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        // Add player
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: player node not found")
            return
        }
        rootNode.addChildNode(playerNode)
        
        // Set up camera and movement
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        guard let cameraNode = cameraNode else {
            print("Warning: camera node not found in player model")
            return
        }
        cameraNode.camera?.fieldOfView = 75
        cameraComponent = CameraComponent(cameraNode: cameraNode)
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
