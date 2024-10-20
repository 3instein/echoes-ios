//  Scene3.swift

import SceneKit
import UIKit

class Scene3: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent?
    var lightNode: SCNNode!
    var doorNode: SCNNode?
    var grandmaNode: SCNNode?
    var scnView: SCNView?
    var isDoorOpen = false
    var isCutscenePlaying = false
    
    // Scene initializer with lightNode as an external dependency
    init(lightNode: SCNNode) {
        super.init()
        
        self.lightNode = lightNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "Scene3.scn") else {
            print("Warning: House scene 'Scene3.scn' not found")
            return
        }
        
        // Add the house's nodes to the root node of the GameScene
        for childNode in houseScene.rootNode.childNodes {
            rootNode.addChildNode(childNode)
        }
        
        // Find the door and grandma nodes in the scene
        doorNode = rootNode.childNode(withName: "Door", recursively: true)
        grandmaNode = rootNode.childNode(withName: "Grandma", recursively: true)
        
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
        
        // Initialize cameraComponent with a valid cameraNode
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        // Temporarily illuminate the scene with ambient lighting
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 250
        ambientLight.color = UIColor.white
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)
        
        // Add the external light node to the scene
        rootNode.addChildNode(lightNode)
        
        // Initialize MovementComponent with lightNode reference
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
        
        startCutscene()
    }
    
    func startCutscene() {
        isCutscenePlaying = true
        disablePlayerMovement()
        
        let delayAction = SCNAction.wait(duration: 0.5)
        
        // Sequence of actions: delay, open door with sound, then move grandma, followed by dialogues and door closing
        let sequence = SCNAction.sequence([delayAction, SCNAction.run { [weak self] _ in
            self?.openDoor {
                self?.moveGrandma {
                    self?.playDialogues()
                }
            }
        }])
        
        rootNode.runAction(sequence)
    }
    
    func disablePlayerMovement() {
        // playerEntity.movementComponent.isEnabled = false
    }
    
    func enablePlayerMovement() {
        // playerEntity.movementComponent.isEnabled = true
    }
    
    func openDoor(completion: @escaping () -> Void) {
        guard let doorNode = doorNode else { return }
        
        // Load and play the door opening sound
        let doorOpenSound = SCNAudioSource(named: "door_open.MP3")!
        doorOpenSound.load()
        
        let openDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: 2.0)
        let playSoundAction = SCNAction.playAudio(doorOpenSound, waitForCompletion: false)
        
        // Sequence to open the door and play the sound
        let doorSequence = SCNAction.group([openDoorAction, playSoundAction])
        
        doorNode.runAction(doorSequence) {
            completion()
        }
        isDoorOpen = true
    }
    
    func moveGrandma(completion: @escaping () -> Void) {
        guard let grandmaNode = grandmaNode else { return }
        let targetPosition = SCNVector3(x: 0, y: -10, z: 0)
        let moveAction = SCNAction.move(to: targetPosition, duration: 2.5)
        
        grandmaNode.runAction(moveAction) { [weak self] in
            self?.enablePlayerMovement()
            self?.isCutscenePlaying = false
            completion()
        }
    }
    
    func playDialogues() {
        // Player greets grandma
        playAudio(named: "scene3_andra_greetings.mp3") {
            // Grandma replies
            self.playAudio(named: "scene3_grandma_greetings.mp3") {
                // Player's thoughts
                self.playAudio(named: "scene3_andra_thoughts.mp3") {
                    // Close the door
                    self.closeDoor()
                }
            }
        }
    }
    
    func closeDoor() {
        guard let doorNode = doorNode else { return }
        
        // Load and play the door closing sound
        let doorCloseSound = SCNAudioSource(named: "door_close.MP3")!
        doorCloseSound.load()
        
        let closeDoorAction = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 2, duration: 2.0)
        let playSoundAction = SCNAction.playAudio(doorCloseSound, waitForCompletion: false)
        
        // Sequence to close the door and play the sound
        let doorSequence = SCNAction.group([closeDoorAction, playSoundAction])
        doorNode.runAction(doorSequence)
    }
    
    // Helper function to play audio files in sequence
    func playAudio(named fileName: String, completion: @escaping () -> Void) {
        let audioSource = SCNAudioSource(named: fileName)!
        audioSource.load()
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: true)
        
        // Run the sound action on the root node
        rootNode.runAction(playAudioAction) {
            completion()
        }
    }
    
    func setupGestureRecognizers(for view: SCNView) {
        self.scnView = view
        guard let cameraComponent = cameraComponent else {
            print("Error: CameraComponent is nil. Cannot set up gesture recognizers.")
            return
        }
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
