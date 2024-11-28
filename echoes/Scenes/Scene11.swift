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
    
    var isDeathPicked: Bool = false
    var isGrandmaPicked = false
    var isAyuPicked = false
    var isRezaPicked = false
    var isRacunPicked = false
    var purpleOverlay: UIView?
    var deathImagesOverlay: UIView?
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        GameViewController.joystickComponent.joystickView.isHidden = true
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene11.scn") else {
            fatalError("Error: Scene named 'scene11.scn' not found")
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
        
        guard let trapDoorNode = rootNode.childNode(withName: "trapDoor", recursively: true) else {
            print("Warning: TrapDoor node not found in the scene.")
            return
        }
        
        // Assuming the animation is part of the trapDoor's animations or has an identifier "trapDoorAnimation"
        if let trapDoorAnimation = trapDoorNode.animationPlayer(forKey: "transform") {
            // If animation is already added to the node
            trapDoorAnimation.play()
        }
        
        playContinuousThunderEffect()
        
        attachAmbientAudioNode(named: "siren.wav", to: "siren", volume: 1000.0)
        attachVoiceNode(named: "s11-polisi.mp3", to: "detective", volume: 1.0)
        
    }
    
    private func attachAmbientAudioNode(named fileName: String, to nodeName: String, volume: Float) {
        guard let node = rootNode.childNode(withName: nodeName, recursively: true) else {
            print("Warning: Node '\(nodeName)' not found in the scene model")
            return
        }
        attachAmbientAudio(to: node, audioFileName: fileName, volume: volume)
    }
    
    private func attachVoiceNode(named fileName: String, to nodeName: String, volume: Float) {
        guard let node = rootNode.childNode(withName: nodeName, recursively: true) else {
            print("Warning: Node '\(nodeName)' not found in the scene model")
            return
        }
        attachAudio(to: node, audioFileName: fileName, volume: volume, delay: 8.0)
    }
    
    func attachAmbientAudio(to node: SCNNode, audioFileName: String, volume: Float = 1.0) {
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
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        print(audioFileName)
        
        if (audioFileName == "s4-andra.wav" || audioFileName == "s11-polisi.mp3") {
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
    
    private func applyCustomFont(to label: UILabel, fontSize: CGFloat) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: fontSize) {
            label.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
    }
    
    func showPurpleBackgroundOverlay(in view: UIView) {
        guard let purpleImage = UIImage(named: "Purple_Background") else {
            print("Error: Image 'Purple_Background' not found.")
            return
        }
        
        let overlayView = UIView(frame: view.bounds)
        overlayView.tag = 999 // Unique tag to find and remove this overlay later
        overlayView.backgroundColor = UIColor(patternImage: purpleImage)
        overlayView.alpha = 0
        view.addSubview(overlayView)
        
        UIView.animate(withDuration: 0.3) {
            overlayView.alpha = 1
        }
        
        // Create and add the "Siapa Pembunuhnya" label at the top
        let titleLabel = UILabel()
        titleLabel.text = "Siapa Pembunuhnya"
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.frame = CGRect(x: 0, y: 30, width: view.bounds.width, height: 30) // Positioned at the top of the screen
        applyCustomFont(to: titleLabel, fontSize: 24) // Apply custom font
        overlayView.addSubview(titleLabel)
        
        let characterImages = ["Character_Reza", "Character_Ayu", "Character_Grandma"]
        let greenCharacterImages = ["Character_Reza_Green", "Character_Ayu_Green", "Character_Grandma_Green"]
        let characterNames = ["Reza", "Ayu", "Grandma"]
        
        // Increased the size and spacing for the images
        let profileImageSize: CGFloat = 175.0 // Bigger image size
        let spacing: CGFloat = 30.0 // Increased spacing between the images
        
        // Adjust the vertical position to be centered below the title
        let totalHeight = profileImageSize + 25 + 20 // Profile image height + label height + spacing
        let centerY = (view.bounds.height - totalHeight) / 2 + 20 // Added some space below the title
        
        for (index, characterImageName) in characterImages.enumerated() {
            guard let characterImage = UIImage(named: characterImageName) else {
                print("Error: Image '\(characterImageName)' not found.")
                continue
            }
            
            let profileImageView = UIImageView(image: characterImage)
            
            // Adjust the xPosition to make room for the larger images and more spacing
            let xPosition = CGFloat(index) * (profileImageSize + spacing) + (view.bounds.width - (CGFloat(characterImages.count) * (profileImageSize + spacing) - spacing)) / 2
            profileImageView.frame = CGRect(x: xPosition, y: centerY, width: profileImageSize, height: profileImageSize) // Keep images centered
            profileImageView.contentMode = .scaleAspectFill
            profileImageView.isUserInteractionEnabled = true
            profileImageView.tag = index
            profileImageView.accessibilityIdentifier = greenCharacterImages[index]
            
            overlayView.addSubview(profileImageView)
            
            let label = UILabel()
            label.text = characterNames[index]
            label.textColor = .white
            label.textAlignment = .center
            label.frame = CGRect(x: xPosition, y: profileImageView.frame.maxY + 25, width: profileImageSize, height: 20) // Adjusted position for text
            applyCustomFont(to: label, fontSize: 16) // Apply custom font
            overlayView.addSubview(label)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCharacterTap(_:)))
            profileImageView.addGestureRecognizer(tapGesture)
        }
    }
    
    
    var isTappedOnce = false // Flag to track if any image has been tapped
    
    @objc func handleCharacterTap(_ sender: UITapGestureRecognizer) {
        guard let tappedImageView = sender.view as? UIImageView,
              let superview = tappedImageView.superview else { return }
        
        // Prevent further taps if one image has already been tapped
        if isTappedOnce {
            return
        }
        
        // Get the green image name from the accessibilityIdentifier
        if let greenImageName = tappedImageView.accessibilityIdentifier,
           let greenImage = UIImage(named: greenImageName) {
            // Replace the tapped image with the green version
            tappedImageView.image = greenImage
        }
        
        // Check if the player tapped on the "Character_Grandma" image
        if let tappedCharacterName = tappedImageView.accessibilityIdentifier, tappedCharacterName == "Character_Grandma_Green" {
            print("Correct") // Print "Correct" if the player tapped Grandma            
            GameViewController.isGrandmaPicked = true
        }
        
        // Check if the player tapped on the "Character_Ayu" image
        if let tappedCharacterName = tappedImageView.accessibilityIdentifier, tappedCharacterName == "Character_Ayu_Green" {
            print("Ayu") // Print "Correct" if the player tapped Ayu
            
            GameViewController.isAyuPicked = true
        }
        
        if let tappedCharacterName = tappedImageView.accessibilityIdentifier, tappedCharacterName == "Character_Reza_Green" {
            print("Reza") // Print "Correct" if the player tapped Ayu
            
            GameViewController.isRezaPicked = true
        }
        
        // Set the flag to true to prevent further taps
        isTappedOnce = true
        
        // Disable user interaction on all other images
        for subview in superview.subviews {
            if let imageView = subview as? UIImageView {
                imageView.isUserInteractionEnabled = false
            }
        }
        
        // After 2 seconds, close the Purple Overlay and show Death Images Overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Remove the Purple Background and character images
            self.clearSubviews(in: superview)
            
            // Show the Death Images Overlay
            self.replaceWithDeathImages(in: superview)
        }
    }
    
    
    // Helper function to clear specific subviews
    func clearSubviews(in view: UIView) {
        for subview in view.subviews {
            if subview is UIImageView || subview is UILabel {
                subview.removeFromSuperview()
            }
        }
    }
    
    func replaceWithDeathImages(in view: UIView?) {
        let deathImages = ["Death_Pukul", "Death_Racun", "Death_Jantung"]
        let deathNames = ["Pukul", "Racun", "Serangan Jantung"]
        let greenDeathImages = ["Death_Pukul_Green", "Death_Racun_Green", "Death_Jantung_Green"]
        
        guard let mainView = view else { return }

        let profileImageSize: CGFloat = 100.0 // Adjusted size to match the other example
        let spacing: CGFloat = 60.0 // Increased spacing to match the other layout

        // Create and add the "Penyebab Kematian Kirana" label at the top
        let titleLabel = UILabel()
        titleLabel.text = "Penyebab Kematian Kirana"
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.frame = CGRect(x: 0, y: 30, width: mainView.bounds.width, height: 30) // Positioned at the top of the screen
        
        // Apply custom font to the title label
            applyCustomFont(to: titleLabel, fontSize: 20)
        mainView.addSubview(titleLabel)

        // Adjust the vertical position to be centered below the title
        let totalHeight = profileImageSize + 25 + 20 // Profile image height + label height + spacing
        let centerY = (mainView.bounds.height - totalHeight) / 2 + 20 // Added space below the title

        for (index, deathImageName) in deathImages.enumerated() {
            guard let deathImage = UIImage(named: deathImageName) else {
                print("Error: Image '\(deathImageName)' not found.")
                continue
            }

            let deathImageView = UIImageView(image: deathImage)
            
            // Adjust the xPosition to make sure images are centered
            let xPosition = CGFloat(index) * (profileImageSize + spacing) + (mainView.bounds.width - (CGFloat(deathImages.count) * (profileImageSize + spacing) - spacing)) / 2
            deathImageView.frame = CGRect(x: xPosition, y: centerY, width: profileImageSize, height: profileImageSize)
            
            // Ensuring that all images scale to fill their frame
            deathImageView.contentMode = .scaleAspectFill // This ensures all images are resized and cropped to fill the given size

            deathImageView.isUserInteractionEnabled = true
            deathImageView.tag = index
            deathImageView.accessibilityIdentifier = greenDeathImages[index]

            mainView.addSubview(deathImageView)

            // Adjust label for longer text
            let label = UILabel()
            label.text = deathNames[index]
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0 // Allow text to wrap to the next line
            label.lineBreakMode = .byWordWrapping // Wrap text by word if necessary
            label.frame = CGRect(x: xPosition, y: deathImageView.frame.maxY + 78, width: profileImageSize, height: 40) // Adjusted height to fit multiple lines
            mainView.addSubview(label)

            // Apply custom font to the label
            applyCustomFont(to: label, fontSize: 16)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeathImageTap(_:)))
            deathImageView.addGestureRecognizer(tapGesture)
        }
    }


    var hasTappedOnce = false // Variable to track if a tap has occurred

    @objc func handleDeathImageTap(_ sender: UITapGestureRecognizer) {
        guard let tappedImageView = sender.view as? UIImageView else { return }
        
        // If we've already tapped once, return early and do nothing
        if hasTappedOnce {
            return
        }

        // Mark that a tap has been made
        hasTappedOnce = true

        // Disable user interaction on all death images after one tap
        for subview in tappedImageView.superview?.subviews ?? [] {
            if let imageView = subview as? UIImageView {
                imageView.isUserInteractionEnabled = false
            }
        }
        
        // Handle the specific tapped image logic (example for "Death_Racun_Green")
        if let tappedDeathImageName = tappedImageView.accessibilityIdentifier, tappedDeathImageName == "Death_Racun_Green" {
            print("Correct") // Print "Correct" if the player tapped Death_Racun
            
            GameViewController.isCauseCorrect = true
        }
        
        // Change the image to its green version (if it has one)
        if let greenImageName = tappedImageView.accessibilityIdentifier,
           let greenImage = UIImage(named: greenImageName) {
            tappedImageView.image = greenImage
        }

        // After 2 seconds, fade out the superview and then remove it
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let superview = tappedImageView.superview else { return }
            
            // Animate fade-out transition
            UIView.animate(withDuration: 0.5, animations: {
                superview.alpha = 0 // Fade out the entire superview
            }, completion: { _ in
                superview.removeFromSuperview() // Remove the superview after fading out
                self.isDeathPicked = true
                
            })
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
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
