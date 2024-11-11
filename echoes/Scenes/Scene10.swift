//  Scene10.swift

import SceneKit
import UIKit

class Scene10: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!
    var cameraNode: SCNNode!
    var doorNode: SCNNode!
    var lockButton: UIButton?
    weak var scnView: SCNView?
    private var keyImageView: UIImageView!
    private var doorImageView: UIImageView!
    private var miniGameCompleted = false
    
    let triggerDistance: Float = 130.0  // Distance within which "Lock" button should appear
    
    init(lightNode: SCNNode, scnView: SCNView) {
        super.init()
        self.lightNode = lightNode
        self.scnView = scnView
        
        // Load room assets
        guard let roomScene = SCNScene(named: "scene10.scn") else {
            print("Warning: Scene named 'scene10.scn' not found")
            return
        }
        
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
        
        doorNode = rootNode.childNode(withName: "door", recursively: true)
        
        rootNode.addChildNode(lightNode)
        
        // Add collision bodies to furniture
        setupFurnitureCollision()
        
        // Set physics contact delegate
        self.physicsWorld.contactDelegate = self
    }
    
    private func setupFurnitureCollision() {
        if let bedNode = rootNode.childNode(withName: "victorian_bed", recursively: true) {
            bedNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            bedNode.physicsBody?.categoryBitMask = 2
            bedNode.physicsBody?.collisionBitMask = 1
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
        if let doorNode = doorNode {
            doorNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            doorNode.physicsBody?.categoryBitMask = 2
            doorNode.physicsBody?.collisionBitMask = 1
        }
    }
    
    func checkProximityToDoor() {
        guard let playerWorldPosition = playerEntity.playerNode?.worldPosition else {
            print("Error: playerNode not found.")
            return
        }
        guard let doorWorldPosition = doorNode?.worldPosition else {
            print("Error: doorNode not found.")
            return
        }
        
        let distance = playerWorldPosition.distance(to: doorWorldPosition)
        
        if distance < triggerDistance && !miniGameCompleted {
            showLockButton()
        } else {
            hideLockButton()
        }
    }
    
    private func showLockButton() {
        if lockButton == nil {
            lockButton = UIButton(type: .system)
            lockButton?.setTitle("Lock", for: .normal)
            
            // Copy style from interactButton
            if let customFont = UIFont(name: "SpecialElite-Regular", size: 16) {
                lockButton?.titleLabel?.font = customFont
            } else {
                print("Failed to load SpecialElite-Regular font.")
            }
            lockButton?.titleLabel?.numberOfLines = -1
            lockButton?.titleLabel?.textAlignment = .center
            lockButton?.backgroundColor = UIColor.white.withAlphaComponent(0.7)
            lockButton?.setTitleColor(.blue, for: .normal)
            lockButton?.layer.cornerRadius = 15
            lockButton?.frame = CGRect(x: 100, y: 100, width: 100, height: 30)
            
            // Add to view and set up action
            scnView?.addSubview(lockButton!)
            lockButton?.addTarget(self, action: #selector(startMiniGame), for: .touchUpInside)
        }
    }
    
    private func hideLockButton() {
        lockButton?.removeFromSuperview()
        lockButton = nil
    }
    
    @objc private func startMiniGame() {
        // Hide the lock button when the mini-game starts
        hideLockButton()
        
        GameViewController.joystickComponent.joystickView.isHidden = true
        setupMiniGameUI()
    }
    
    private func setupMiniGameUI() {
        // Create door image view in the center of the screen
        doorImageView = UIImageView(image: UIImage(named: "door.jpg"))
        doorImageView.frame = CGRect(x: scnView!.bounds.midX - 85, y: scnView!.bounds.midY - 200, width: 180, height: 380)
        scnView?.addSubview(doorImageView)
        
        // Create key image view at the bottom of the screen
        keyImageView = UIImageView(image: UIImage(named: "key.jpg"))
        keyImageView.frame = CGRect(x: 100, y: scnView!.bounds.height - 250, width: 100, height: 100)
        scnView?.addSubview(keyImageView)
        
        // Enable dragging on the key image view
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        keyImageView.addGestureRecognizer(panGesture)
        keyImageView.isUserInteractionEnabled = true
    }
    
    @objc private func handleDrag(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: scnView)
        if let view = gesture.view {
            view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        }
        gesture.setTranslation(.zero, in: scnView)
        
        // Check for success when drag ends
        if gesture.state == .ended {
            checkForSuccess()
        }
    }
    
    private func checkForSuccess() {
        if keyImageView.frame.intersects(doorImageView.frame) {
            keyImageView.removeFromSuperview()
            doorImageView.removeFromSuperview()
            miniGameCompleted = true
            GameViewController.joystickComponent.joystickView.isHidden = false
            print("Door successfully locked")
        }
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
