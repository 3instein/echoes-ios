//
//  Scene9.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 27/10/24.
//

import SceneKit
import UIKit

class Scene9: SCNScene, SCNPhysicsContactDelegate {
    var stepSound: SCNAudioSource!
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    
    weak var scnView: SCNView?
    var playButton: UIButton?
    
    let transitionTriggerPosition = SCNVector3(0, 0, 0);
    let triggerDistance: Float = 100.0
    let fourthTargetPosition = SCNVector3(-239.248, 81.08, 35.81)
    
    init(lightNode: SCNNode, scnView: SCNView) {
        self.scnView = scnView
        GameViewController.joystickComponent.showJoystick()
        super.init()
        self.lightNode = lightNode
        
        guard let houseScene = SCNScene(named: "Scene9.scn") else {
            print("Warning: House scene 'Scene 9.scn' not found")
            return
        }
        
        setupPlayerEntityAndMovementComponent()
        scnView.pointOfView = cameraNode
        
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
        
        setupPlayerEntityAndMovementComponent()
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
        
        // Load sounds and other setup
        if let woodNode = rootNode.childNode(withName: "woodenFloor", recursively: false) {
            attachAudio(to: woodNode, audioFileName: "woodenFloor.wav", volume: 0.7, delay: 0)
        }
        
        if let clockNode = rootNode.childNode(withName: "clockTicking", recursively: true) {
            attachAudio(to: clockNode, audioFileName: "clockTicking.wav", volume: 0.7, delay: 0)
        }
        
        self.physicsWorld.contactDelegate = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startPlayerMovement()
        }
        
        guard let lightRainNode = rootNode.childNode(withName: "outsideRain", recursively: true) else {
            print("Warning: LightRain node named 'lightRain' not found in house model")
            return
        }
        
        attachAudio(to: lightRainNode, audioFileName: "outsideRain.wav", volume: 0.5, delay: 0)
        
        stepSound = SCNAudioSource(fileNamed: "step.mp3")
        if stepSound == nil {
            print("Error: step.mp3 file not found.")
        } else {
            stepSound.shouldStream = false
            stepSound.isPositional = false
            stepSound.volume = 1.0
            stepSound.load()
        }
        
        addBlueFireAnimationNode()
    }

    func joystickMoved() {
        playStepSound()
    }
    
    private func playKiranaSound1(on node: SCNNode, completion: (() -> Void)? = nil) {
        guard let kiranaSound = SCNAudioSource(fileNamed: "s9-kirana1.wav") else {
            print("Error: Audio file 's9-kirana1.wav' not found")
            return
        }
        
        kiranaSound.shouldStream = false
        kiranaSound.isPositional = true
        kiranaSound.volume = 1.0
        kiranaSound.load()
        
        print("Audio loaded successfully, preparing to play 's9-kirana1.wav'")
        
        let playKiranaAction = SCNAction.playAudio(kiranaSound, waitForCompletion: true)
        let completionAction = SCNAction.run { _ in
            print("Audio 's9-kirana1.wav' playback finished.")
            completion?()  // Call the completion handler if provided
        }
        
        let sequenceAction = SCNAction.sequence([playKiranaAction, completionAction])
        node.runAction(sequenceAction)
    }
    
    private func performJumpscare() {
        guard let grandmaNode = rootNode.childNode(withName: "grandma", recursively: true),
              let cameraNode = self.cameraNode else {
            print("Error: Grandma or camera node not found in Scene9")
            return
        }
        
        // Spotlight on grandma's face for jumpscare
        let spotlight = SCNLight()
        spotlight.type = .spot
        spotlight.intensity = 1500
        spotlight.spotInnerAngle = 30
        spotlight.spotOuterAngle = 60
        spotlight.color = UIColor.white
        spotlight.castsShadow = true
        
        let spotlightNode = SCNNode()
        spotlightNode.light = spotlight
        spotlightNode.position = SCNVector3(grandmaNode.position.x, grandmaNode.position.y, grandmaNode.position.z)
        spotlightNode.look(at: grandmaNode.position)
        
        grandmaNode.addChildNode(spotlightNode)
        
        // Rotate camera and zoom in for jumpscare effect
        let lookAtAction = SCNAction.rotateTo(
            x: CGFloat(180),
            y: CGFloat(grandmaNode.position.y),
            z: CGFloat(grandmaNode.position.z),
            duration: 1.0
        )
        let zoomInAction = SCNAction.move(by: SCNVector3(0, 0, -1.5), duration: 0.5)
        let jumpscareSequence = SCNAction.sequence([lookAtAction, zoomInAction])
        cameraNode.runAction(jumpscareSequence)
        
        // After jumpscare, remove effects and play new sound
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.stopBackgroundSound()
            self.playAndraSound()
        }
    }

    // Function to stop the background sound
    private func stopBackgroundSound() {
        if let backgroundNode = rootNode.childNode(withName: "backgroundSound", recursively: true) {
            backgroundNode.removeAllAudioPlayers()
            print("Background sound stopped.")
        }
    }

    // Function to play s9-andra.wav sound, followed by s9-reza2.wav
    private func playAndraSound() {
        guard let andraSound = SCNAudioSource(fileNamed: "s9-andra.wav") else {
            print("Error: Audio file 's9-andra.wav' not found")
            return
        }

        andraSound.shouldStream = false
        andraSound.isPositional = true
        andraSound.volume = 1.0
        andraSound.load()

        print("Audio loaded successfully, preparing to play 's9-andra.wav'")
        
        let playAndraAction = SCNAction.playAudio(andraSound, waitForCompletion: true)
        let playReza2Action = SCNAction.run { [weak self] _ in
            self?.playReza2Sound()  // Play s9-reza2.wav after andra finishes
        }

        let sequence = SCNAction.sequence([playAndraAction, playReza2Action])
        cameraNode.runAction(sequence)
    }

    // Function to play s9-reza2.wav sound
    private func playReza2Sound() {
        guard let reza2Sound = SCNAudioSource(fileNamed: "s9-reza2.wav") else {
            print("Error: Audio file 's9-reza2.wav' not found")
            return
        }

        reza2Sound.shouldStream = false
        reza2Sound.isPositional = true
        reza2Sound.volume = 1.0
        reza2Sound.load()

        print("Audio loaded successfully, preparing to play 's9-reza2.wav'")
        
        let playReza2Action = SCNAction.playAudio(reza2Sound, waitForCompletion: true)
        let completionAction = SCNAction.run { [weak self] _ in
            print("Audio 's9-reza2.wav' playback finished.")
            self?.showButton()  // Show button after audio completes
        }

        let sequenceAction = SCNAction.sequence([playReza2Action, completionAction])
        cameraNode.runAction(sequenceAction)
    }
    
    private func playBackground(on node: SCNNode) {
        guard let backgroundSound = SCNAudioSource(fileNamed: "ritualBackground.wav") else {
            print("Error: Audio file 'ritualBackground.wav' not found")
            return
        }
        
        backgroundSound.shouldStream = false
        backgroundSound.isPositional = true
        backgroundSound.volume = 1.0
        backgroundSound.loops = true
        backgroundSound.load()
        
        print("Audio loaded successfully, preparing to play 'ritualBackground.wav'")
        
        let playBackgroundAction = SCNAction.playAudio(backgroundSound, waitForCompletion: false)
        node.runAction(playBackgroundAction)
    }
    
    private func playRain(on node: SCNNode) {
        guard let backgroundSound = SCNAudioSource(fileNamed: "outsiderRain.wav") else {
            print("Error: Audio file 'outsideRain.wav' not found")
            return
        }
        
        backgroundSound.shouldStream = false
        backgroundSound.isPositional = true
        backgroundSound.volume = 1.0
        backgroundSound.loops = true
        backgroundSound.load()
        
        print("Audio loaded successfully, preparing to play 'ritualBackground.wav'")
        
        let playBackgroundAction = SCNAction.playAudio(backgroundSound, waitForCompletion: false)
        node.runAction(playBackgroundAction)
    }
    
    private func setupPlayerEntityAndMovementComponent() {
        guard let playerNode = self.rootNode.childNode(withName: "playerNodeName", recursively: true) else {
            print("Error: Player node not found in Scene9")
            return
        }
        
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        
        playerEntity = PlayerEntity(in: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        GameViewController.playerEntity = playerEntity
        
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        GameViewController.playerEntity.movementComponent = movementComponent
        
        let targetPosition = SCNVector3(295.243, 392.056, 33.859)
        movementComponent.movePlayer(to: targetPosition, duration: 20.0) {
            print("Player has reached the target position.")
        }
    }
    
    private func startPlayerMovement() {
        guard let movementComponent = GameViewController.playerEntity?.movementComponent else {
            print("MovementComponent not found.")
            return
        }
        
        let firstTargetPosition = SCNVector3(184.505, 516.979, 35.809)
        let secondTargetPosition = SCNVector3(211.776, 778.045, 35.809)
        let thirdTargetPosition = SCNVector3(211.776, 778.045, -15.809)
        let fourthTargetPosition = SCNVector3(-239.248, 81.08, 35.81)
        
        // Move to the first target position
        movementComponent.movePlayer(to: firstTargetPosition, duration: 10.0) {
            print("Player has reached the first target position.")
            self.playStepSound() // Play step sound at the start of each movement
            
            // Move to the second target position
            movementComponent.movePlayer(to: secondTargetPosition, duration: 5.0) {
                print("Player has reached the second target position.")
                self.playStepSound() // Play step sound at the start of each movement
                
                // Move to the third target position
                movementComponent.movePlayer(to: thirdTargetPosition, duration: 5.0) {
                    print("Player has reached the third target position.")
                    self.playStepSound() // Play step sound at the start of each movement
                    
                    self.scnView?.alpha = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        UIView.animate(withDuration: 0.5, animations: {
                            self.scnView?.alpha = 1
                        }) { _ in
                            if let playerNode = self.playerEntity.playerNode {
                                self.addCandleLightEffects(around: playerNode)
                            }
                            
                            print("Checking if kiranaNode1 exists for playback.")
                            if let kiranaNode1 = self.rootNode.childNode(withName: "s9-kirana1", recursively: true) {
                                self.playKiranaSound1(on: kiranaNode1) {
                                    self.moveGrandma()
                                    
                                    print("Playing background sound.")
                                    if let backgroundNode = self.rootNode.childNode(withName: "backgroundSound", recursively: true) {
                                        self.playBackground(on: backgroundNode)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                            print("Checking if kiranaNode2 exists for playback.")
                                            if let kiranaNode2 = self.rootNode.childNode(withName: "s9-kirana2", recursively: false) {
                                                self.playKiranaSound2(on: kiranaNode2)
                                            } else {
                                                print("Error: kiranaNode2 not found in the scene.")
                                            }
                                        }
                                    }
                                }
                            } else {
                                print("Error: kiranaNode1 not found in the scene.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func moveGrandma() {
        guard let grandmaNode = rootNode.childNode(withName: "grandma", recursively: true) else {
            print("Error: Grandma node not found in Scene9")
            return
        }
        
        let grandmaTargetPosition = SCNVector3(141.743, 767.443, 22.355)
        let moveDuration: TimeInterval = 5.0
        
        let moveAction = SCNAction.move(to: grandmaTargetPosition, duration: moveDuration)
        grandmaNode.runAction(moveAction) {
            print("Grandma has reached her target position.")
        }
    }
    
    func checkProximityToTransition() -> Bool {
        guard let playerPosition = playerEntity.playerNode?.position else { return false }
        let distance = playerPosition.distance(to: transitionTriggerPosition)
        return distance < triggerDistance
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true
        }
        
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        let waitAction = SCNAction.wait(duration: delay)
        let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
        node.runAction(sequenceAction)
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    private func blinkEffectWithDelay(completion: @escaping () -> Void) {
        guard let scnView = self.scnView else {
            completion()
            return
        }
        
        scnView.alpha = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            
            UIView.animate(withDuration: 0.5, animations: {
                scnView.alpha = 1
            }) { _ in
                completion()
            }
        }
    }
    
    private func showButton() {
        guard let view = scnView else {
            print("Error: scnView is nil.")
            return
        }
        
        DispatchQueue.main.async {
            // Create and configure the button
            self.playButton = UIButton(type: .system)
            self.playButton?.setTitle("Run", for: .normal)
            self.playButton?.backgroundColor = UIColor(hex: "3C3EBB")
            self.playButton?.setTitleColor(.white, for: .normal)
            self.playButton?.layer.cornerRadius = 10
            self.playButton?.translatesAutoresizingMaskIntoConstraints = false
            self.playButton?.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
            
            // Apply the custom font to the button
            if let customFont = UIFont(name: "SpecialElite-Regular", size: 28) {                self.playButton?.titleLabel?.font = customFont
            } else {
                print("Failed to load SpecialElite-Regular font.")
            }
            
            // Add the button to the view
            view.addSubview(self.playButton!)
            
            // Set button constraints
            NSLayoutConstraint.activate([
                self.playButton!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                self.playButton!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
                self.playButton!.widthAnchor.constraint(equalToConstant: 180),
                self.playButton!.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            view.layoutIfNeeded()
        }
    }

    private func playKiranaSound2(on node: SCNNode, completion: (() -> Void)? = nil) {
        guard let kiranaSound = SCNAudioSource(fileNamed: "s9-kirana2.wav") else {
            print("Error: Audio file 's9-kirana2.wav' not found")
            return
        }
        
        kiranaSound.shouldStream = false
        kiranaSound.isPositional = true
        kiranaSound.volume = 1.0
        kiranaSound.load()
        
        print("Audio loaded successfully, preparing to play 's9-kirana2.wav'")
        
        let playKiranaAction = SCNAction.playAudio(kiranaSound, waitForCompletion: true)
        let completionAction = SCNAction.run { _ in
            print("Audio 's9-kirana2.wav' playback finished.")
            self.turnOffCandleLightEffects()  // Turn off candle light effects
            self.performJumpscare()
            completion?()
        }
        
        let sequenceAction = SCNAction.sequence([playKiranaAction, completionAction])
        node.runAction(sequenceAction)
    }

    // Function to turn off candle light effects
    private func turnOffCandleLightEffects() {
        rootNode.enumerateChildNodes { (node, _) in
            if node.name == "candleLightNode" {
                node.removeFromParentNode()
            }
        }
        print("Candle light effects turned off.")
    }

    func addCandleLightEffects(around playerNode: SCNNode) {
        let candleOffsets = [
            SCNVector3(x: 1.2, y: 1, z: 1.2)
        ]
        
        for offset in candleOffsets {
            let candleNode = SCNNode()
            candleNode.name = "candleLightNode"  // Add a name for easy removal later
            
            candleNode.position = SCNVector3(
                playerNode.position.x + offset.x,
                playerNode.position.y + offset.y,
                playerNode.position.z + offset.z
            )
            
            let candleGeometry = SCNCylinder(radius: 0.07, height: 0.3)
            candleGeometry.firstMaterial?.diffuse.contents = UIColor.white
            let candleVisualNode = SCNNode(geometry: candleGeometry)
            candleVisualNode.position = SCNVector3(0, 0.15, 0)
            candleNode.addChildNode(candleVisualNode)
            
            let flameGeometry = SCNSphere(radius: 0.02)
            flameGeometry.firstMaterial?.diffuse.contents = UIColor.orange
            let flameNode = SCNNode(geometry: flameGeometry)
            flameNode.position = SCNVector3(0, 0.3, 0)
            candleNode.addChildNode(flameNode)
            
            let candleLight = SCNLight()
            candleLight.type = .omni
            candleLight.intensity = 100
            candleLight.color = UIColor.blue
            candleNode.light = candleLight
            
            playerNode.parent?.addChildNode(candleNode)
            
            let flickerAction = SCNAction.sequence([
                SCNAction.customAction(duration: 0.15) { _,_ in candleLight.intensity = 130 },
                SCNAction.wait(duration: 0.05),
                SCNAction.customAction(duration: 0.2) { _,_ in candleLight.intensity = 160 },
                SCNAction.wait(duration: 0.05),
                SCNAction.customAction(duration: 0.1) { _,_ in candleLight.intensity = 140 },
                SCNAction.wait(duration: 0.07),
                SCNAction.customAction(duration: 0.1) { _,_ in candleLight.intensity = 150 }
            ])
            
            let repeatFlicker = SCNAction.repeatForever(flickerAction)
            candleNode.runAction(repeatFlicker)
        }
    }

    private func addBlueFireAnimationNode() {
        // Create the fire particle system
        guard let fireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil) else {
            print("Error: Could not find 'smoothFire.scnp' particle system.")
            return
        }
        
        // Create a new SCNNode for the fire effect
        let fireNode = SCNNode()
        
        // Position the fire near the player node (adjust position if needed)
        fireNode.position = SCNVector3(0, 1.5, 0) // Adjust this to control placement relative to player
        
        // Attach the particle system to the fire node
        fireNode.addParticleSystem(fireParticleSystem)
        fireNode.name = "blueFire"  // Assign a name for reference
        
        playerEntity.playerNode?.addChildNode(fireNode)
        
        print("Blue fire node added and is always active.")
    }
    
    private func playStepSound() {
        guard let playerNode = playerEntity.playerNode else {
            print("Player node is nil")
            return
        }
        guard let stepSound = stepSound else {
            print("Step sound is nil")
            return
        }
        let playStepAction = SCNAction.playAudio(stepSound, waitForCompletion: false)
        playerNode.runAction(playStepAction)
    }
    
    @objc private func buttonTapped() {
        print("Button tapped!")
        playButton?.removeFromSuperview()
        
        guard let movementComponent = playerEntity?.movementComponent else {
            print("Error: Movement component is not available.")
            return
        }
        
        // Move player to the 4th target position
        let fourthTargetPosition = SCNVector3(-239.248, 81.08, 35.81) // Define the 4th target position here
        movementComponent.movePlayer(to: fourthTargetPosition, duration: 5.0) {
            print("Player has reached the 4th destination.")
            self.playStepSound()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
