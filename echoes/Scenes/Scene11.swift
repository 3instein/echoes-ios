//
//  Scene11.swift
//  echoes
//
//  Created by Reynaldi Kindarto on 05/11/24.
//

import SceneKit
import UIKit

class Scene11: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    
    weak var scnView: SCNView?
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene.scn") else {
            print("Warning: House scene 'Scene4.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        // Create a new player entity and initialize it using the house scene's root node
        playerEntity = PlayerEntity(in: rootNode, cameraNode: cameraNode, lightNode: lightNode)
        
        guard let playerNode = playerEntity.playerNode else {
            print("Warning: Player node named 'Player' not found in house model")
            return
        }
        
        // Add player node to the GameScene's rootNode
        rootNode.addChildNode(playerNode)
        
        // Attach the existing camera node from the player model to the scene
        cameraNode = playerNode.childNode(withName: "Camera", recursively: true)
        guard let cameraNode = cameraNode else {
            print("Warning: Camera node named 'Camera' not found in Player model")
            return
        }
        
        // Make optional adjustments to the camera if needed
        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = false
        
        // Add the camera component to handle the camera logic
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
        
        playContinuousThunderEffect()
        
        self.physicsWorld.contactDelegate = self
    }
    
    func playContinuousThunderEffect() {
        let thunderLightNodes = ["thunderLightA", "thunderLightB", "thunderLightC", "thunderLightD"]

        for lightName in thunderLightNodes {
            
            guard let thunderLightNode = rootNode.childNode(withName: lightName, recursively: true) else {
                print("Warning: \(lightName) node not found in the scene.")
                continue
            }
            
            thunderLightNode.light?.type = .omni
            thunderLightNode.light?.intensity = 0  // Set initial intensity to 0 (off)
            thunderLightNode.light?.color = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0) // Blueish tint
            
            // Define actions to simulate a thunder flash and play random thunder sound
            let flashOnAction = SCNAction.run { _ in
                thunderLightNode.light?.intensity = 5000
                self.playRandomThunderSound()
            }
            let flashOffAction = SCNAction.run { _ in
                thunderLightNode.light?.intensity = 0
            }
            
            // Significantly slower flash sequence for enhanced realism
            let flashDuration = SCNAction.wait(duration: 2.0)  // Prolonged flash duration
            let delayBetweenFlashes = SCNAction.wait(duration: 3.5)  // Longer delay between flashes

            // Thunder sequence with one or two slow flashes for dramatic effect
            let thunderSequence = SCNAction.sequence([
                flashOnAction,
                flashDuration,
                flashOffAction,
                delayBetweenFlashes,
                flashOnAction,
                flashDuration,
                flashOffAction
            ])
            
            // Blackout period with a random delay to create suspense between sequences
            let blackoutAction = SCNAction.run { _ in
                thunderLightNode.light?.intensity = 0
            }
            let blackoutDuration = SCNAction.wait(duration: Double.random(in: 4.0...6.0))
            let blackoutSequence = SCNAction.sequence([blackoutAction, blackoutDuration])
            
            // Randomized pause between sequences for natural effect
            let randomDelayAction = SCNAction.run { _ in
                let randomDelay = Double.random(in: 12.0...16.0)  // Increased delay for extended pause
                thunderLightNode.runAction(SCNAction.wait(duration: randomDelay))
            }
            
            // Complete sequence with thunder, blackout, and random delay
            let continuousThunderSequence = SCNAction.sequence([thunderSequence, blackoutSequence, randomDelayAction])
            
            // Run the thunder sequence in an infinite loop
            let continuousThunderLoop = SCNAction.repeatForever(continuousThunderSequence)
            
            // Add a random delay at the start to avoid synchronized flashing
            let initialDelay = Double.random(in: 4.0...8.0)
            thunderLightNode.runAction(SCNAction.sequence([SCNAction.wait(duration: initialDelay), continuousThunderLoop]))
        }
    }

    // Helper function to play a random thunder sound
    func playRandomThunderSound() {
        let thunderSoundFiles = ["thunder1.wav", "thunder2.wav", "thunder3.wav", "thunder4.wav", "thunder5.wav"]
        guard let randomSoundFile = thunderSoundFiles.randomElement() else { return }
        
        guard let audioSource = SCNAudioSource(fileNamed: randomSoundFile) else {
            print("Warning: Audio file '\(randomSoundFile)' not found")
            return
        }
        
        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = 0.5
        
        // Play the audio with no delay for immediate thunder effect
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the audio action on the scene’s root node
        rootNode.runAction(playAudioAction)
    }

    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        if (audioFileName == "s4-andra.wav"){
            audioSource.isPositional = false
        } else {
            audioSource.isPositional = true
        }
        
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        
        // Set looping for continuous rain sound
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true  // This ensures the rain loops without breaking
        }
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        let waitAction = SCNAction.wait(duration: delay)
        let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
        node.runAction(sequenceAction)
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
