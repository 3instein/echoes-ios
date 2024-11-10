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
        rootNode.addChildNode(lightNode)
        
        // Add collision bodies to furniture
        setupFurnitureCollision()
        
        // Set physics contact delegate
        self.physicsWorld.contactDelegate = self
    }
    
    private func setupFurnitureCollision() {
        // Define collision setup for each piece of furniture
        
        if let bedNode = rootNode.childNode(withName: "victorian_bed", recursively: true) {
            bedNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            bedNode.physicsBody?.categoryBitMask = 2  // Define as static object
            bedNode.physicsBody?.collisionBitMask = 1  // Collides with player
        }
        
        if let leftEndTable = rootNode.childNode(withName: "end_table01", recursively: true) {
            leftEndTable.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            leftEndTable.physicsBody?.categoryBitMask = 2
            leftEndTable.physicsBody?.collisionBitMask = 1
        }
        
        if let rightEndTable = rootNode.childNode(withName: "end_table02", recursively: true) {
            rightEndTable.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            rightEndTable.physicsBody?.categoryBitMask = 2
            rightEndTable.physicsBody?.collisionBitMask = 1
        }
        
        if let doorNode = rootNode.childNode(withName: "door", recursively: true) {
            doorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            doorNode.physicsBody?.categoryBitMask = 2
            doorNode.physicsBody?.collisionBitMask = 1
        }
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
