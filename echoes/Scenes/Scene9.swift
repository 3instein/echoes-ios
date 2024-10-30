//
//  Scene9.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 27/10/24.
//

import SceneKit
import UIKit

class Scene9: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    
    weak var scnView: SCNView?
    var playButton: UIButton?

    let transitionTriggerPosition = SCNVector3(62.983, 98.335, 29.035)
    let triggerDistance: Float = 100.0
    
    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()
        super.init()
        self.lightNode = lightNode
        
        guard let houseScene = SCNScene(named: "Scene9.scn") else {
            print("Warning: House scene 'Scene 9.scn' not found")
            return
        }
        
        setupPlayerEntityAndMovementComponent()
        scnView?.pointOfView = cameraNode
        
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
    }

    private func playKiranaSound(on node: SCNNode) {
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
        
        // After the audio completes, show the button
        let completionAction = SCNAction.run { _ in
            print("Audio 's9-kirana1.wav' playback finished. Showing button.")
            self.showButton()
        }
        
        let sequenceAction = SCNAction.sequence([playKiranaAction, completionAction])
        node.runAction(sequenceAction)
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
        
        let firstTargetPosition = SCNVector3(240.705, 148.812, 30.403)
        let secondTargetPosition = SCNVector3(295.243, 392.056, 33.859)
        
        movementComponent.movePlayer(to: firstTargetPosition, duration: 10.0) {
            print("Player has reached the first target position.")
            
            movementComponent.movePlayer(to: secondTargetPosition, duration: 10.0) {
                print("Player has reached the second target position.")
                
                // Start the blink effect and fade-in animation
                self.scnView?.alpha = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    
                    UIView.animate(withDuration: 0.5, animations: {
                        self.scnView?.alpha = 1
                    }) { _ in
                        // Add candle light effects around the player
                        if let playerNode = self.playerEntity.playerNode {
                            self.addCandleLightEffects(around: playerNode)
                        }
                        
                        // Play kirana sound after candles are lit
                        if let kiranaNode = self.rootNode.childNode(withName: "s9-kirana1", recursively: true) {
                            self.playKiranaSound(on: kiranaNode)
                        }
                        
                        // Move Grandma after the candle effect
                        self.moveGrandma()
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
        
        let grandmaTargetPosition = SCNVector3(174.379, 377.979, 32.562)
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
    func addCandleLightEffects(around playerNode: SCNNode) {
        let candleOffsets = [
            SCNVector3(x: 1.2, y: 1, z: 1.2),
            SCNVector3(x: -1.2, y: 0, z: -1.2)
        ]
        
        for offset in candleOffsets {
            let candleNode = SCNNode()
            
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
            candleLight.intensity = 150
            candleLight.color = UIColor.orange
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
    
    private func showButton() {
        guard let view = scnView else {
            print("Error: scnView is nil.")
            return
        }
        print("scnView is available; proceeding to show button.")
        
        // Create a button
        playButton = UIButton(type: .system)
        playButton?.setTitle("Continue", for: .normal)
        playButton?.backgroundColor = UIColor.systemBlue
        playButton?.setTitleColor(.white, for: .normal)
        playButton?.layer.cornerRadius = 10
        playButton?.translatesAutoresizingMaskIntoConstraints = false
        playButton?.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
        // Add the button to the view
        view.addSubview(playButton!)
        
        // Set button constraints
        NSLayoutConstraint.activate([
            playButton!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton!.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            playButton!.widthAnchor.constraint(equalToConstant: 120),
            playButton!.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        view.layoutIfNeeded()  // Force layout update
    }
    
    @objc private func buttonTapped() {
        print("Button tapped!")
        playButton?.removeFromSuperview()
        // Add any additional actions you want to perform when the button is tapped
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
