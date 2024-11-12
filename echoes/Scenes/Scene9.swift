//
//  Scene9.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 27/10/24.
//

import SceneKit
import UIKit

class Scene9: SCNScene, SCNPhysicsContactDelegate {
    var rezaFollowTimer: Timer?
    private var doorAnimationPlayed = false
    var stepSound: SCNAudioSource!
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var movementComponent: MovementComponent?
    var positionTimer: Timer?

    weak var scnView: SCNView?
    var playButton: UIButton?
    
    let doorTriggerPosition1 = SCNVector3(-7.592, 494.06, 35.81)
    let doorTriggerPosition2 = SCNVector3(151.224, 504.715, 35.81)
    let doorTriggerPosition3 = SCNVector3(151.224, 504.715, 35.81)
    let doorTriggerDistance: Float = 5.0
    
    let transitionTriggerPosition = SCNVector3(-239.248, 81.08, 35.81);
    let triggerDistance: Float = 100.0
    let fourthTargetPosition = SCNVector3(-239.248, 81.08, 35.81)
    let initialPlayerPosition = SCNVector3(211.776, 778.045, -15.809)
    let initialRezaPosition = SCNVector3(181.743, 767.443, 2.355)
    let fifthTargetPosition = SCNVector3(211.776, 778.045, 2.355)
    let rezaDestination1 = SCNVector3(161.442, 516.906, 32.361)
    let rezaDestination2 = SCNVector3(-32.376, 516.906, 32.361)
    let rezaDestination3 = SCNVector3(-50.514, 585.614, 32.361)
    let finalRezaDestination = SCNVector3(-222.207, 89.067, 26.907)
    
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
        
        guard let outsideRain = rootNode.childNode(withName: "outsideRain", recursively: true) else {
            print("Warning: LightRain node named 'lightRain' not found in house model")
            return
        }
        
        attachAudio(to: outsideRain, audioFileName: "outsideRain.wav", volume: 0.1, delay: 0)
        
        stepSound = SCNAudioSource(fileNamed: "step.mp3")
        if stepSound == nil {
            print("Error: step.mp3 file not found.")
        } else {
            stepSound.shouldStream = false
            stepSound.isPositional = false
            stepSound.volume = 1.0
            stepSound.load()
        }
        
        setupBlueFireEffect()
        startPositionLogging()
        
        if let ritualNode = rootNode.childNode(withName: "ritual", recursively: true) {
            let glowLight = SCNLight()
            glowLight.type = .omni
            glowLight.color = UIColor.blue
            glowLight.intensity = 1000               // Higher intensity for a strong glow
            glowLight.attenuationStartDistance = 0
            glowLight.attenuationEndDistance = 10    // Adjust distance for the glow effect
            
            let lightNode = SCNNode()
            lightNode.light = glowLight
            lightNode.position = SCNVector3(0, 0, 1) // Position relative to ritual node
            
            ritualNode.addChildNode(lightNode)
        }
        
        //        if let url = Bundle.main.url(forResource: "reza idle", withExtension: "dae") {
        //            let sceneSource = SCNSceneSource(url: url, options: nil)
        //            let animationKeys = sceneSource?.identifiersOfEntries(withClass: CAAnimation.self) ?? []
        //
        //            if let rezaNode = rootNode.childNode(withName: "reza", recursively: true) {
        //                for key in animationKeys {
        //                    if let animation = sceneSource?.entryWithIdentifier(key, withClass: CAAnimation.self) {
        //                        animation.repeatCount = .infinity
        //                        rezaNode.addAnimation(animation, forKey: key)
        //                    }
        //                }
        //            }
        //        }
        
        //        if let url = Bundle.main.url(forResource: "reza idle", withExtension: "dae") {
        //            let sceneSource = SCNSceneSource(url: url, options: nil)
        //            let animationKeys = sceneSource?.identifiersOfEntries(withClass: CAAnimation.self) ?? []
        //
        //            for key in animationKeys {
        //                print("Available animation key: \(key)")
        //            }
        //        }
        
        if let doorNode = rootNode.childNode(withName: "doorNode", recursively: true) {
            animateDoorRotation(doorNode)
        }
        
    }
    
    private func lockPlayerControls() {
        print("Locking player controls")
        joystickComponent?.isEnabled = false
        joystickComponent?.hideJoystick()
        cameraComponent?.lockCamera()
    }

    private func unlockPlayerControls() {
        print("Unlocking player controls")
        joystickComponent?.isEnabled = true
        joystickComponent?.showJoystick()
        cameraComponent?.unlockCamera()
    }
    
    func animateDoorRotation(_ doorNode: SCNNode) {
        let rotateToOpen = SCNAction.rotateTo(x: 0, y: 0, z: -CGFloat.pi / 2, duration: 2.0, usesShortestUnitArc: true)
        doorNode.runAction(rotateToOpen)
    }
    
    deinit {
        positionTimer?.invalidate()
        rezaFollowTimer?.invalidate()
    }
    
    private func startPositionLogging() {
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  let playerNode = self.playerEntity?.playerNode else { return }
            
            let playerPosition = playerNode.position
            print("Player's current position: \(playerPosition)")
            
            // Check if the player is close enough to the door trigger position
            if !self.doorAnimationPlayed && playerPosition.distance(to: self.doorTriggerPosition1) < self.doorTriggerDistance {
                self.doorAnimationPlayed = true
                if let doorNode = self.rootNode.childNode(withName: "doorNode", recursively: true) {
                    self.animateDoorRotation(doorNode)
                }
            }
            

        }
    }
    
    private func setupBlueFireEffect() {
        guard let blueFireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil) else {
            print("Error: Particle system 'smoothFire.scnp' not found.")
            return
        }
        
        blueFireParticleSystem.loops = true
        
        let blueFirePositions = [
            SCNVector3(230.776, 690.000, 35.809),
            SCNVector3(270.776, 710.000, 35.809),
            SCNVector3(210.776, 710.000, 35.809),
            SCNVector3(290.776, 730.000, 35.809),
            SCNVector3(190.776, 730.000, 35.809),
            SCNVector3(310.776, 750.000, 35.809), //y++ going fireplace, x++ going sofa
            SCNVector3(170.776, 750.000, 35.809),
            SCNVector3(310.776, 770.000, 35.809), //y++ going fireplace, x++ going sofa
            SCNVector3(170.776, 770.000, 35.809),
            SCNVector3(310.776, 790.000, 35.809), //y++ going fireplace, x++ going sofa
            SCNVector3(170.776, 790.000, 35.809),
            SCNVector3(290.776, 810.000, 35.809),
            SCNVector3(190.776, 810.000, 35.809),
            SCNVector3(270.776, 830.000, 35.809),
            SCNVector3(210.776, 830.000, 35.809),
            SCNVector3(250.776, 850.000, 35.809),
            SCNVector3(230.776, 850.000, 35.809),
            
            SCNVector3(-31.227, 586.321, 32.361),
            SCNVector3(116.685, 484.724, 32.361),
        ]
        
        for position in blueFirePositions {
            let blueFireNode = SCNNode()
            blueFireNode.position = position
            blueFireNode.addParticleSystem(blueFireParticleSystem)
            rootNode.addChildNode(blueFireNode)
            print("Blue fire particle system added at position \(position)")
        }
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
            completion?()
        }
        
        let sequenceAction = SCNAction.sequence([playKiranaAction, completionAction])
        node.runAction(sequenceAction)
    }
    
    private func performJumpscare(completion: (() -> Void)? = nil) {
        guard let cameraNode = self.cameraNode, let playerNode = self.playerEntity?.playerNode else {
            print("Error: Camera or Player node not found in Scene9")
            completion?()
            return
        }
        
        let turnAroundAction = SCNAction.rotateBy(x: 0, y: .pi, z: 0, duration: 0.5)
        
        let playJumpscareSound = SCNAction.run { _ in
            if let jumpscareSound = SCNAudioSource(fileNamed: "jumpscare.wav") {
                jumpscareSound.shouldStream = false
                jumpscareSound.isPositional = true
                jumpscareSound.volume = 1.0
                jumpscareSound.load()
                cameraNode.runAction(SCNAction.playAudio(jumpscareSound, waitForCompletion: false))
                print("Jumpscare sound played.")
            } else {
                print("Error: jumpscare.wav file not found.")
            }
        }
        
        let movementSequence = SCNAction.sequence([turnAroundAction, playJumpscareSound])
        
        cameraNode.runAction(movementSequence) {
            print("Player has completed the jumpscare rotation.")
            
            playerNode.position = self.fifthTargetPosition
            print("Player moved to fifth target position at \(self.fifthTargetPosition).")
            
            completion?()
        }
    }
    
    private func stopBackgroundSound() {
        if let backgroundNode = rootNode.childNode(withName: "backgroundSound", recursively: true) {
            backgroundNode.removeAllAudioPlayers()
            print("Background sound stopped.")
        }
    }
    
    private func playAndraSound(completion: (() -> Void)? = nil) {
        guard let andraSound = SCNAudioSource(fileNamed: "s9-andra.wav") else {
            print("Error: Audio file 's9-andra.wav' not found")
            completion?()
            return
        }
        
        andraSound.shouldStream = false
        andraSound.isPositional = true
        andraSound.volume = 1.0
        andraSound.load()
        
        let playAndraAction = SCNAction.playAudio(andraSound, waitForCompletion: true)
        cameraNode.runAction(playAndraAction) {
            completion?()
        }
    }
    
    private func playReza2Sound(completion: (() -> Void)? = nil) {
        guard let reza2Sound = SCNAudioSource(fileNamed: "s9-reza2.wav") else {
            print("Error: Audio file 's9-reza2.wav' not found")
            completion?()
            return
        }
        
        reza2Sound.shouldStream = false
        reza2Sound.isPositional = true
        reza2Sound.volume = 1.0
        reza2Sound.load()
        
        let playReza2Action = SCNAction.playAudio(reza2Sound, waitForCompletion: true)
        let completionAction = SCNAction.run { _ in
            print("Audio 's9-reza2.wav' playback finished.")
            
            self.moveReza(to: self.finalRezaDestination )
            
            completion?()
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
        
        // Lock controls and hide joystick before playing sound
        lockPlayerControls()
        
        let playBackgroundAction = SCNAction.playAudio(backgroundSound, waitForCompletion: true)
        
        // Sequence the actions
        let sequence = SCNAction.sequence([playBackgroundAction])
        node.runAction(sequence)
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
        
        movementComponent.movePlayer(to: doorTriggerPosition1, duration: 5.0) {
            movementComponent.movePlayer(to: firstTargetPosition, duration: 5.0) {
                print("Player has reached the first target position.")
                self.playStepSound()
                
                movementComponent.movePlayer(to: secondTargetPosition, duration: 5.0) {
                    print("Player has reached the second target position.")
                    self.playStepSound()
                    
                    movementComponent.movePlayer(to: thirdTargetPosition, duration: 5.0) {
                        print("Player has reached the third target position.")
                        self.playStepSound()
                        
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
                                        self.moveReza(to: self.initialRezaPosition)
                                        
                                        print("Playing background sound.")
                                        if let backgroundNode = self.rootNode.childNode(withName: "backgroundSound", recursively: true) {
                                            self.playBackground(on: backgroundNode)
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                                print("Checking if kiranaNode2 exists for playback.")
                                                if let kiranaNode2 = self.rootNode.childNode(withName: "s9-kirana2", recursively: false) {
                                                    self.playKiranaSound2(on: kiranaNode2)
                                                    guard let kiranaSound2 = self.rootNode.childNode(withName: "s9-kirana2", recursively: false) else {
                                                        print("Kiranasound2 not found in house model")
                                                        return
                                                    }
                                                    
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
    }
    
    private func moveReza(to position: SCNVector3) {
        guard let rezaNode = rootNode.childNode(withName: "reza", recursively: true) else {
            print("Error: Reza node not found in Scene9")
            return
        }
        
        let moveDuration: TimeInterval = 10.0
        let moveAction = SCNAction.move(to: position, duration: moveDuration)
        
        rezaNode.runAction(moveAction) {
            print("Reza has reached her new target position at \(position).")
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
    
    private func playKiranaSound2(on node: SCNNode, completion: (() -> Void)? = nil) {
        guard let kiranaSound = SCNAudioSource(fileNamed: "s9-kirana2.wav") else {
            print("Error: Audio file 's9-kirana2.wav' not found")
            return
        }
        
        kiranaSound.shouldStream = false
        kiranaSound.isPositional = true
        kiranaSound.volume = 0.5
        kiranaSound.load()
        
        print("Audio loaded successfully, preparing to play 's9-kirana2.wav'")
        
        let playKiranaAction = SCNAction.playAudio(kiranaSound, waitForCompletion: true)
        let completionAction = SCNAction.run { [weak self] _ in
            print("Audio 's9-kirana2.wav' playback finished.")
            
            self?.stopBackgroundSound()
            
            self?.unlockPlayerControls()
            
            self?.performJumpscareAndFollowUp()
            completion?()
        }
        
        let sequenceAction = SCNAction.sequence([playKiranaAction, completionAction])
        node.runAction(sequenceAction)
    }
    
    private func performJumpscareAndFollowUp() {
        performJumpscare { [weak self] in
            self?.playAndraSound { [weak self] in
                self?.playReza2Sound { [weak self] in
                    self?.showButton()
                }
            }
        }
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float = 1.0) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.loops = true
        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        
        audioSource.volume = volume
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        node.runAction(playAudioAction)
    }
    
    // Modify the addCandleLightEffects method
    func addCandleLightEffects(around playerNode: SCNNode) {
        // Set up candle light effect
        let candleOffsets = [
            SCNVector3(x: 1.2, y: 1, z: 1.2)
        ]
        
        for offset in candleOffsets {
            let candleNode = SCNNode()
            candleNode.name = "candleLightNode"
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
        
        // Add BlueFire effect in multiple positions independently of candle light
        if let blueFireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil) {
            let blueFirePositions = [
                SCNVector3(250.776, 690.000, 35.809),
                SCNVector3(230.776, 690.000, 35.809),
                SCNVector3(270.776, 710.000, 35.809),
                SCNVector3(210.776, 710.000, 35.809),
                SCNVector3(290.776, 730.000, 35.809),
                SCNVector3(190.776, 730.000, 35.809),
                SCNVector3(310.776, 750.000, 35.809),
                SCNVector3(170.776, 750.000, 35.809)
            ]
            
            for position in blueFirePositions {
                let blueFireNode = SCNNode()
                blueFireNode.position = position
                blueFireNode.addParticleSystem(blueFireParticleSystem)
                rootNode.addChildNode(blueFireNode)
                print("Blue fire particle system added at position \(position)")
            }
        } else {
            print("Error: Particle system 'smoothFire.scnp' not found.")
        }
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
        print("Run button tapped!")
        
        if let movementComponent = playerEntity?.movementComponent {
            movementComponent.movementSpeed = 120
            print("Increased speed to 120")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                movementComponent.movementSpeed = 60
                print("Speed reset to normal")
            }
        }
    }
    
    private func showButton() {
        guard let view = scnView else {
            print("Error: scnView is nil.")
            return
        }
        
        DispatchQueue.main.async {
            self.playButton = UIButton(type: .system)
            self.playButton?.setTitle("Run", for: .normal)
            self.playButton?.backgroundColor = UIColor(hex: "3C3EBB") // Matching joystick color
            self.playButton?.setTitleColor(.white, for: .normal)
            self.playButton?.layer.cornerRadius = 50 // Make it circular, similar to the joystick
            self.playButton?.layer.masksToBounds = true
            self.playButton?.translatesAutoresizingMaskIntoConstraints = false
            self.playButton?.titleLabel?.font = UIFont(name: "SpecialElite-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24)
            
            self.playButton?.addTarget(self, action: #selector(self.increaseSpeed), for: .touchDown)
            self.playButton?.addTarget(self, action: #selector(self.resetSpeed), for: [.touchUpInside, .touchUpOutside])
            
            view.addSubview(self.playButton!)
            
            NSLayoutConstraint.activate([
                self.playButton!.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                self.playButton!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
                self.playButton!.widthAnchor.constraint(equalToConstant: 100),
                self.playButton!.heightAnchor.constraint(equalToConstant: 100)
            ])
            
            self.playButton?.alpha = 0.3
            UIView.animate(withDuration: 0.5) {
                self.playButton?.alpha = 1.0
            }
            
            self.startRezaFollowingPlayer()
        }
    }
    
    private func startRezaFollowingPlayer() {
        guard let rezaNode = rootNode.childNode(withName: "reza", recursively: true),
              let playerNode = playerEntity?.playerNode else {
            print("Error: Reza or Player node not found in Scene9")
            return
        }

        rezaNode.removeAllActions()

        let minimumDistance: Float = 100.0
        let moveSpeed: Float = 0.1

        let followPlayerAction = SCNAction.run { [weak self] _ in
            guard let self = self else { return }

            let playerPosition = playerNode.position
            let rezaPosition = rezaNode.position
            let distanceToPlayer = playerPosition.distance(to: rezaPosition)

            if distanceToPlayer > minimumDistance {
                let direction = SCNVector3(
                    (playerPosition.x - rezaPosition.x) * moveSpeed,
                    (playerPosition.y - rezaPosition.y) * moveSpeed,
                    (playerPosition.z - rezaPosition.z) * moveSpeed
                )
                rezaNode.position = SCNVector3(
                    rezaPosition.x + direction.x,
                    rezaPosition.y + direction.y,
                    rezaPosition.z + direction.z
                )
            }
        }

        let repeatFollowAction = SCNAction.repeatForever(SCNAction.sequence([followPlayerAction, SCNAction.wait(duration: 0.1)]))
        rezaNode.runAction(repeatFollowAction)
    }
    
    private func moveRezaToSequence() {
        guard let rezaNode = rootNode.childNode(withName: "reza", recursively: true) else {
            print("Error: Reza node not found in Scene9")
            return
        }
        
        // Define the sequence of positions for Reza
        let moveToPosition1 = SCNAction.move(to: rezaDestination1, duration: 5.0)
        let moveToPosition2 = SCNAction.move(to: rezaDestination2, duration: 5.0)
        let moveToPosition3 = SCNAction.move(to: rezaDestination3, duration: 5.0)
        
        // Create a sequence action for moving through each position
        let sequenceAction = SCNAction.sequence([moveToPosition1, moveToPosition2, moveToPosition3])
        
        // Run the action on Reza
        rezaNode.runAction(sequenceAction) {
            print("Reza has reached all designated target positions.")
        }
    }
    
    @objc private func increaseSpeed() {
        print("Run button pressed, increasing speed")
        if let movementComponent = playerEntity?.movementComponent {
            movementComponent.movementSpeed = 120
        }
    }
    
    @objc private func resetSpeed() {
        print("Run button released, resetting speed")
        if let movementComponent = playerEntity?.movementComponent {
            movementComponent.movementSpeed = 60
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}

extension SCNVector3 {
    static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}
