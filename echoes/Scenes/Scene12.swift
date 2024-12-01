//  Scene12.swift

import SceneKit
import UIKit

class Scene12: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var killerNode: SCNNode!
    var grandmalastNode: SCNNode!
    var treeNode: SCNNode!
    var eyeClosingNode: SCNNode?
    var slideBenar: UIView?
    var slideshowImages: [SCNNode] = []
    var slideshowTimer: Timer?
    weak var scnView: SCNView?
    var durationSalah = 0.0
    var isFinished: Bool = false
    var isGameEnding: Bool = false
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        GameViewController.joystickComponent.joystickView.isHidden = true

        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene12.scn") else {
            fatalError("Error: Scene named 'scene12.scn' not found")
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
        cameraComponent = CameraComponent(cameraNode: cameraNode, playerNode: playerNode)
        
        rootNode.addChildNode(lightNode)
 
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 0.5, delay: 0)
        }
        
        playContinuousThunderEffect()
        
        grandmalastNode = rootNode.childNode(withName: "grandmaLast", recursively: true)
        treeNode = rootNode.childNode(withName: "tree", recursively: true)

        if GameViewController.isGrandmaPicked && GameViewController.isCauseCorrect {
            // Play the correct answer sound
            attachAudio(to: rootNode, audioFileName: "s12-benar.mp3", volume: 1.0, delay: 5.0)
                        
            // Stop swaying after the audio completes (34 seconds in this case)
            DispatchQueue.main.asyncAfter(deadline: .now() + 40.0) { [weak self] in
                // Stop the slideshow
                self?.slideBenar?.removeFromSuperview()
                self?.slideshowTimer?.invalidate()
                self?.slideshowImages.forEach { $0.isHidden = true }
                
                self?.grandmalastNode.isHidden = false
                self?.showKiller()
            }
        } else {
            // Determine which "salah" audio to play based on the previous player's choice
            var wrongAnswerAudioFile = "s12-salah.mp3" // Default audio

            if GameViewController.isAyuPicked {
                wrongAnswerAudioFile = "s12-salahAyu.mp3"
            } else if GameViewController.isRezaPicked {
                wrongAnswerAudioFile = "s12-salahReza.mp3"
            }
            
            // Play the appropriate wrong answer sound
            attachAudio(to: rootNode, audioFileName: wrongAnswerAudioFile, volume: 1.0, delay: 5.0)

            if GameViewController.isGrandmaPicked {
                durationSalah = 3.0
            } else {
                durationSalah = 25.0
            }
            // Stop swaying after the audio completes (20 seconds in this case)
            DispatchQueue.main.asyncAfter(deadline: .now() + durationSalah) { [weak self] in
                self?.slideBenar?.removeFromSuperview()
                self?.slideshowTimer?.invalidate()
                self?.slideshowImages.forEach { $0.isHidden = true }
                
                self?.grandmalastNode.isHidden = true
                self?.showKiller()
            }
        }
            
        self.physicsWorld.contactDelegate = self
    }
    
    // Combined setup and start slideshow
    func setupAndStartSlideshow(on view: UIView) {
        var imageNames = [""]
        // If we have reached the final image (index 4), stop the timer and remove the view
        var maxIndex = 4
        var transitionTime = 0.0
        
        if GameViewController.isGrandmaPicked && GameViewController.isCauseCorrect {
            imageNames = ["benar-1.jpeg", "benar-2.jpeg", "benar-3.jpeg", "benar-4.jpeg"]
            maxIndex = 4
            transitionTime = 5.2
        } else {
            if GameViewController.isAyuPicked {
                imageNames = ["salahAyu-1.jpeg", "salahAyu-2.jpeg", "salahAyu-3.jpeg"]
            } else if GameViewController.isRezaPicked {
                imageNames = ["salahReza-1.jpeg", "salahReza-2.jpeg", "salahReza-3.jpeg"]
            }
            maxIndex = 3
            transitionTime = 3.0
        }
                
        // Create the slideBenar view
        slideBenar = UIView()
        slideBenar?.backgroundColor = UIColor.black.withAlphaComponent(1)
        
        let backgroundSize = CGSize(width: view.bounds.width, height: view.bounds.height)
        slideBenar?.frame = CGRect(
            x: (view.bounds.width - backgroundSize.width) / 2,
            y: (view.bounds.height - backgroundSize.height) / 2,
            width: backgroundSize.width,
            height: backgroundSize.height
        )
        slideBenar?.layer.cornerRadius = 0
        slideBenar?.layer.borderWidth = 0
        slideBenar?.clipsToBounds = true
        view.addSubview(slideBenar!)
        
        // Create an array to hold the image views
        var slideshowImages: [UIImageView] = []
        
        // Load each image and add it as an UIImageView to slideBenar
        for imageName in imageNames {
            let imageView = UIImageView(image: UIImage(named: imageName))
            imageView.frame = slideBenar?.bounds ?? CGRect.zero
            imageView.contentMode = .scaleAspectFill
            imageView.isHidden = true // Hide initially
            slideBenar?.addSubview(imageView)
            slideshowImages.append(imageView)
        }
        
        var currentIndex = 0
        
        // Set the initial image to be shown
        slideshowImages[currentIndex].isHidden = false
        slideshowImages[currentIndex].alpha = 0
        UIView.animate(withDuration: 0.7) {
            slideshowImages[currentIndex].alpha = 1
        }
        
        // Start the slideshow with a timer
        slideshowTimer = Timer.scheduledTimer(withTimeInterval: transitionTime, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            if currentIndex == maxIndex {
                self.slideshowTimer?.invalidate()  // Stop the slideshow timer
                self.slideshowTimer = nil  // Clear the timer reference
                self.slideBenar!.backgroundColor = UIColor.black.withAlphaComponent(0)

                // Remove all subviews and the slideBenar view
                self.slideBenar!.subviews.forEach { $0.removeFromSuperview() }
                self.slideBenar!.removeFromSuperview()
                self.slideBenar = nil  // Clear the slideBenar reference
                self.slideshowImages.removeAll()
                
                return  // Exit the timer's closure to prevent further execution
            }
            
            // Hide the current image with a fade-out effect
            UIView.animate(withDuration: 0.7, animations: {
                slideshowImages[currentIndex].alpha = 0
            }) { _ in
                slideshowImages[currentIndex].isHidden = true
                
                // Show the next image with a fade-in effect
                currentIndex += 1
                if currentIndex < slideshowImages.count {
                    slideshowImages[currentIndex].isHidden = false
                    slideshowImages[currentIndex].alpha = 0
                    UIView.animate(withDuration: 0.7) {
                        slideshowImages[currentIndex].alpha = 1
                    }
                }
            }
            
            print(currentIndex)
        }
    }

    func showKiller() {
        if GameViewController.isGrandmaPicked && GameViewController.isCauseCorrect {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 3.0
            self.cameraNode.look(at: self.grandmalastNode.position)
            SCNTransaction.commit()

            self.attachAudio(to: self.grandmalastNode!, audioFileName: "jumpscare3.wav", volume: 40.0, delay: 0)
            
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-637.748, -2378.121, 10), duration: 7.0) {
                self.attachAudio(to: self.grandmalastNode, audioFileName: "s12-grandmaLaugh.wav", volume: 0.2, delay: 0.0)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
                    self!.isFinished = true
                }
            }
        } else {
            // Move policeCars node to the back when the answer is incorrect
            guard let policeCarsNode = rootNode.childNode(withName: "policeCars", recursively: true) else {
                print("Warning: policeCars node not found.")
                return
            }
            
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-996.541, -3430.96, 120), duration: 3.0) {
                
            }
            
            attachAudio(to: policeCarsNode, audioFileName: "startPoliceCar.wav", volume: 0.7, delay: 0)
            
            attachAudio(to: policeCarsNode, audioFileName: "siren.wav", volume: 1.0, delay: 1.0)

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            self.cameraNode.look(at: policeCarsNode.position)
            SCNTransaction.commit()
            
            // Add a delay before the police cars start moving back
            let waitAction = SCNAction.wait(duration: 2.0) // 2-second delay
            let moveBackAction = SCNAction.moveBy(x: 0, y: -1500, z: 0, duration: 5.0)
            moveBackAction.timingMode = .easeInEaseOut // Smooth animation
            
            // Combine wait and move actions
            let sequence = SCNAction.sequence([waitAction, moveBackAction])
            
            // Execute the actions
            policeCarsNode.runAction(sequence)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.isFinished = true
            }
        }
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
        audioSource.volume = 0.15
        
        // Play the audio with no delay for immediate thunder effect
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the audio action on the scene’s root node
        rootNode.runAction(playAudioAction)
    }
    
    func fadeScreenToBlack(on view: UIView) {
        DispatchQueue.main.async {
            let blackOverlay = UIView(frame: view.bounds)
            blackOverlay.backgroundColor = .black
            blackOverlay.alpha = 0
            view.addSubview(blackOverlay)
            
            UIView.animate(withDuration: 2.0, animations: {
                blackOverlay.alpha = 1.0
            }, completion: { _ in
                blackOverlay.removeFromSuperview()
                print("Fade to black complete")
            })
        }
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.volume = volume
        audioSource.isPositional = true
        audioSource.shouldStream = false
        // Set looping for specific audio files if needed
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true
        }
        audioSource.load()

        // Create a new node to attach the audio and position it
        let audioNode = SCNNode()
        node.addChildNode(audioNode)

        // Play audio with delay
        let playAudioAction = SCNAction.sequence([
            SCNAction.wait(duration: delay),
            SCNAction.playAudio(audioSource, waitForCompletion: false)
        ])
        
        // Play the audio
        audioNode.runAction(playAudioAction)
    }

    // Apply the custom font to a label
    private func applyCustomFont(to label: UILabel, fontSize: CGFloat) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: fontSize) {
            label.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}

