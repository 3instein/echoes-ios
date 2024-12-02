//  Scene10.swift

import SceneKit
import UIKit

class Scene10: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!
    var cameraNode: SCNNode!
    var doorNode: SCNNode!
    var trapdoorNode: SCNNode!
    var knockDoorNode: SCNNode!
    var lockButton: UIButton?
    var enterButton: UIButton?
    var trapDoorEntered = false
    
    weak var scnView: SCNView?
    private var keyImageView: UIImageView!
    private var doorImageView: UIImageView!
    private var instructionLabel: UILabel?
    private var miniGameCompleted = false
    private var isMiniGameActive = false
    
    let doorTriggerDistance: Float = 135.0  // Distance "Lock" button for door room should appear
    let trapdoorTriggerDistance: Float = 110.0  // Distance "Enter" button for trap door should appear
    
    init(lightNode: SCNNode, scnView: SCNView) {
        super.init()
        self.lightNode = lightNode
        self.scnView = scnView
        
        // Load room assets
        guard let roomScene = SCNScene(named: "scene10.scn") else {
            fatalError("Error: Scene named 'scene10.scn' not found")
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
        trapdoorNode = rootNode.childNode(withName: "trap_door", recursively: true)
        knockDoorNode = rootNode.childNode(withName: "knock_door", recursively: true)
        
        rootNode.addChildNode(lightNode)
        
        setupFurnitureCollision()
        playAndraSound()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showInstructionLabel()
        }
        
        self.physicsWorld.contactDelegate = self
    }
    
    private func playAndraSound() {
        guard let andraSound = SCNAudioSource(fileNamed: "s10-andra.mp3") else {
            print("Error: Sound file 's10-andra.mp3' not found in the project bundle")
            return
        }
        
        andraSound.shouldStream = false
        andraSound.isPositional = false
        andraSound.volume = 2.0
        andraSound.load()
        
        let playAndraSound = SCNAction.sequence([
            SCNAction.wait(duration: 1.0), // 1-second delay
            SCNAction.playAudio(andraSound, waitForCompletion: false)
        ])
        
        // Run the action on the root node or any other node where you want the sound to originate
        rootNode.runAction(playAndraSound)
    }
    
    private func showInstructionLabel() {
        guard let scnView = scnView else { return }
        
        // Create the label if it doesn't exist
        if instructionLabel == nil {
            instructionLabel = UILabel()
            instructionLabel?.text = "Quickly lock the door!"
            instructionLabel?.textAlignment = .center
            instructionLabel?.textColor = UIColor.white
            instructionLabel?.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            instructionLabel?.layer.cornerRadius = 10
            instructionLabel?.clipsToBounds = true
            instructionLabel?.alpha = 0.0
            applyCustomFont(to: instructionLabel!, fontSize: 14)
            
            // Add the label to the SCNView
            scnView.addSubview(instructionLabel!)
        }
        
        // Position and size the label
        let offsetFromTop: CGFloat = 150 // Adjust offset from top
        instructionLabel?.frame = CGRect(
            x: (scnView.frame.width - 195) / 2, // Center horizontally
            y: scnView.frame.height / 2 - offsetFromTop, // Position slightly above center
            width: 195,
            height: 25
        )
        
        // Fade in the label
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel?.alpha = 1.0
        }
    }
    
    private func hideInstructionLabel() {
        // Fade out and hide the label
        UIView.animate(withDuration: 0.5, animations: {
            self.instructionLabel?.alpha = 0.0
        }, completion: { _ in
            self.instructionLabel?.removeFromSuperview()
            self.instructionLabel = nil
        })
    }
    
    private func applyCustomFont(to label: UILabel, fontSize: CGFloat) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: fontSize) {
            label.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
    }
    
    private func setupFurnitureCollision() {
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
    
    func checkProximity() {
        guard let playerWorldPosition = playerEntity.playerNode?.worldPosition else {
            print("Error: playerNode not found.")
            return
        }
        
        // Check proximity to door for locking mini-game
        if let doorWorldPosition = doorNode?.worldPosition, !isMiniGameActive {
            let distanceToDoor = playerWorldPosition.distanceTo(doorWorldPosition)
            if distanceToDoor < doorTriggerDistance && !miniGameCompleted {
                showLockButton()
            } else {
                hideLockButton()
            }
        }
        
        // Check proximity to trapdoor and enable glow if within range
        if let trapdoorWorldPosition = trapdoorNode?.worldPosition, !trapDoorEntered {
            let distanceToTrapdoor = playerWorldPosition.distanceTo(trapdoorWorldPosition)
            if distanceToTrapdoor < trapdoorTriggerDistance {
                showEnterButton()
                toggleGlowEffect(isEnabled: true)
            } else {
                hideEnterButton()
                toggleGlowEffect(isEnabled: false)
            }
        }
    }
    
    private func showLockButton() {
        if lockButton == nil {
            lockButton = UIButton(type: .system)
            lockButton?.setTitle("Lock", for: .normal)
            styleButton(lockButton!)
            lockButton?.frame = CGRect(x: 100, y: 100, width: 100, height: 30)
            scnView?.addSubview(lockButton!)
            lockButton?.addTarget(self, action: #selector(startMiniGame), for: .touchUpInside)
        }
    }
    
    private func hideLockButton() {
        lockButton?.removeFromSuperview()
        lockButton = nil
    }
    
    private func showEnterButton() {
        if enterButton == nil {
            enterButton = UIButton(type: .system)
            enterButton?.setTitle("Enter", for: .normal)
            styleButton(enterButton!)
            enterButton?.frame = CGRect(x: 150, y: 150, width: 100, height: 30)
            scnView?.addSubview(enterButton!)
            enterButton?.addTarget(self, action: #selector(enterTrapdoor), for: .touchUpInside)
        }
    }
    
    private func hideEnterButton() {
        enterButton?.removeFromSuperview()
        enterButton = nil
    }
    
    private func styleButton(_ button: UIButton) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: 16) {
            button.titleLabel?.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
        button.titleLabel?.numberOfLines = -1
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        button.setTitleColor(.blue, for: .normal)
        button.layer.cornerRadius = 15
    }
    
    private func toggleGlowEffect(isEnabled: Bool) {
        guard let trapdoorMaterial = trapdoorNode?.geometry?.firstMaterial else {
            print("Error: trapdoor material not found")
            return
        }
        
        if isEnabled {
            trapdoorMaterial.emission.contents = UIColor.cyan.withAlphaComponent(0.8)
        } else {
            trapdoorMaterial.emission.contents = UIColor.black
        }
    }
    
    @objc private func startMiniGame() {
        hideLockButton()
        GameViewController.joystickComponent.joystickView.isHidden = true
        setupMiniGameUI()
        hideInstructionLabel()
    }
    
    private func setupMiniGameUI() {
        // Start the mini-game
        isMiniGameActive = true
        
        // Hide the lock button immediately
        hideLockButton()
        
        // Set up the mini-game UI as before
        doorImageView = UIImageView(image: UIImage(named: "door.jpg"))
        doorImageView.frame = CGRect(x: scnView!.bounds.midX - 85, y: scnView!.bounds.midY - 200, width: 180, height: 380)
        scnView?.addSubview(doorImageView)
        
        keyImageView = UIImageView(image: UIImage(named: "key.jpg"))
        keyImageView.frame = CGRect(x: 100, y: scnView!.bounds.height - 250, width: 100, height: 100)
        scnView?.addSubview(keyImageView)
        
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
        
        if gesture.state == .ended {
            checkForSuccess()
        }
    }
    
    private func checkForSuccess() {
        if keyImageView.frame.intersects(doorImageView.frame) {
            keyImageView.removeFromSuperview()
            doorImageView.removeFromSuperview()
            miniGameCompleted = true
            isMiniGameActive = false
            
            GameViewController.joystickComponent.joystickView.isHidden = false
            playDoorKnockSound()
            print("Door successfully locked")
        }
    }
    
    private func playDoorKnockSound() {
        guard let knockDoorNode = knockDoorNode else {
            print("Error: Knock door node not found in the scene")
            return
        }
        
        guard let knockSound = SCNAudioSource(fileNamed: "doorKnockHard.wav") else {
            print("Error: Knock sound file 'doorKnockHard.wav' not found in the project bundle")
            return
        }
        
        knockSound.shouldStream = false
        knockSound.isPositional = false
        knockSound.loops = true
        knockSound.volume = 1.0
        knockSound.load()
        
        let playKnockSound = SCNAction.playAudio(knockSound, waitForCompletion: false)
        knockDoorNode.runAction(playKnockSound)
    }
    
    @objc private func enterTrapdoor() {
        hideEnterButton()
        trapDoorEntered = true
        print("Trapdoor interaction completed. Scene 10 will transition to Scene 11.")
        
        DispatchQueue.main.async {
            print("Attempting to start transition via GameViewController.shared.")
            GameViewController.shared.startTransitionToScene11()
        }
    }
    
    func checkProximityToTransition() -> Bool {
        return trapDoorEntered
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SCNVector3 {
    func distanceTo(_ vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
}
