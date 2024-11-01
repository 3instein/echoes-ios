//
//  Scene8.swift
//  echoes
//
//  Created by Angeline Ivana on 26/10/24.
//

import SceneKit
import UIKit

class Scene8: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!

    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var necklaceNode: SCNNode!
    var dollNode: SCNNode!
    var toiletDoorCloseNode: SCNNode!
    var toiletDoorOpenNode: SCNNode!
    
    weak var scnView: SCNView?
    
    var playButton: UIButton?  // Store a reference to the play button
    var clueCabinetNode: SCNNode!
    var cluePipeNode: SCNNode!
    
    var hasKey = true  // Track if the player has the key
    var isCabinetOpened = false  // Track if the player has the key
    var isCabinetDone = false  // Track if the player has the key

    var isPlayingPipe = false  // Track if the player has the key
    
    let proximityDistance: Float = 180.0  // Define a proximity distance
    
    var pipeBackground: UIView?
    var isNecklaceObtained: Bool = false  // Track if the game is completed
    
    // Define the label for displaying the message
    private let necklaceLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.alpha = 0.0
        return label
    }()
    
    var timer: Timer?
    var timeLimit: Int = 35
    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.alpha = 0.0
        return label
    }()
    
    var isPipeClicked = false
    
    var rotatingPipeNode: SCNNode?  // Node for the rotating pipe
    
    var wipeDirections: [String: String] = [
        "pipeclue-2": "down",
        "pipeclue-3": "down",
        "pipeclue-7": "right",
        "pipeclue-8": "down",
        "pipeclue-10": "up",
        "pipeclue-11": "up",
        "pipeclue-12": "right",
        "pipeclue-14": "right",
        "pipeclue-15": "down",
        "pipeclue-17": "up",
        "pipeclue-18": "up",
        "pipeclue-19": "right",
        "pipeclue-21": "right",
        "pipeclue-22": "down",
        "pipeclue-23": "down"
    ]
    
    var correctRotationCounter: Int = 0  // Counter to track correct rotations
    
    // Define a list to store the sequence of correctly rotated pipes
    var correctlyRotatedPipes: [String] = []
    var previouslyGreenPipes: Set<String> = []  // Track pipes that were previously green
    
    let fixedPipeSequence: [String] = [
        "pipeclue-2", "pipeclue-3", "pipeclue-7", "pipeclue-8",
        "pipeclue-12", "pipeclue-11", "pipeclue-10", "pipeclue-14",
        "pipeclue-15", "pipeclue-19", "pipeclue-18", "pipeclue-17",
        "pipeclue-21", "pipeclue-22", "pipeclue-23"
    ]
    
    var currentPipeIndex: Int = 0 // Property to track the current pipe index
    var lastActivatedPipeIndex: Int = -1 // Track the last activated pipe index
    
    var isNecklaceFalling = false
    var isPipeFailed = false
    var isDollJumpscare = false
    var isJumpscareDone = false
    
    let transitionTriggerPosition = SCNVector3(-169.992, 461.627, 100)
    let triggerDistance: Float = 80.0
    
    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()
        
        super.init()
        self.lightNode = lightNode
        //        scnView?.pointOfView = cameraNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene8.scn") else {
            print("Warning: House scene 'Scene 8.scn' not found")
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
        
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 0.5, delay: 0)
        }
        
        if let andraParentNode = rootNode.childNode(withName: "player", recursively: true) {
            if let andraNode = andraParentNode.childNode(withName: "s8-andra1", recursively: false) {
                attachAudio(to: andraNode, audioFileName: "s8-andra1.mp3", volume: 5, delay: 2)
            }
        }
        
        if let pipeNode = rootNode.childNode(withName: "pipe_3", recursively: true) {
            attachAudio(to: pipeNode, audioFileName: "pipeNecklace.mp3", volume: 0.3, delay: 2)
        }
        
        clueCabinetNode = rootNode.childNode(withName: "smallCabinetBody", recursively: true)
        
        cluePipeNode = rootNode.childNode(withName: "pipe_1", recursively: true)
        
        necklaceNode = rootNode.childNode(withName: "necklace", recursively: true)
                
        dollNode = rootNode.childNode(withName: "doll", recursively: true)
        
        toiletDoorOpenNode = rootNode.childNode(withName: "toiletDoorOpen", recursively: true)
        
        toiletDoorCloseNode = rootNode.childNode(withName: "toiletDoorClose", recursively: true)

        attachAudio(to: toiletDoorCloseNode, audioFileName: "door_close.mp3", volume: 0.5, delay: 0.2)

        dollNode.isHidden = true
        
        toiletDoorOpenNode.isHidden = true

        self.physicsWorld.contactDelegate = self
        
        // Apply font to necklaceLabel safely
        applyCustomFont(to: necklaceLabel, fontSize: 14)
    }
    
    func pipeCompleted() {
        if currentPipeIndex == 15 {
            print("Puzzle solved! The necklace is revealed.")
            
            pipeBackground?.removeFromSuperview()
            timeLabel.removeFromSuperview()
            timer?.invalidate()
            
            // Loop through each puzzle piece
            for i in 1...8 {
                let pipeNodeName = "pipe_\(i)"
                if let pipeNode = rootNode.childNode(withName: pipeNodeName, recursively: true) {
                    // Set the category bitmask for post-processing
                    pipeNode.isHidden = false
                }
            }
            
            // Delay to wait until the necklace finishes falling
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                guard let cameraNode = self?.cameraNode else { return }
                
                // Get current Euler angles and only adjust X and Z axes
                let eulerAngles = cameraNode.eulerAngles
                cameraNode.eulerAngles = SCNVector3(
                    (self?.roundedAngle(eulerAngles.x * 180 / .pi) ?? 0) * .pi / 180, // Round X-axis
                    eulerAngles.y, // Keep Y-axis unchanged
                    (self?.roundedAngle(eulerAngles.z * 180 / .pi) ?? 0) * .pi / 180  // Round Z-axis
                )
                
                GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-272.92, 406.476, -80), duration: 3.0) {
                    self?.cameraNode.look(at: self!.necklaceNode.position)

                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 2.0
                    self?.cameraNode.camera?.fieldOfView = 50  // Adjust this value for closer zoom
                    SCNTransaction.commit()

                    self?.attachAudio(to: self!.cluePipeNode!, audioFileName: "pipeAfterOut.wav", volume: 0.4, delay: 0)

                    self?.animateNecklaceFalling(from: self!.cluePipeNode!)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 11.5) { [weak self] in
                self?.cameraNode.camera?.fieldOfView = 75

                GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-272.92, 406.476, 25), duration: 2.0) {

                }
                self?.isPlayingPipe = false
                self?.isNecklaceFalling = true
                self?.isNecklaceObtained = true
                self?.jumpscareDoll()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) { [weak self] in
                    self?.addBlueFireAnimationNode()
                }
            }
        }
    }
    
    func roundedAngle(_ angle: Float) -> Float {
        // Define the set of target angles
        let targets: [Float] = [-180, -90, 0, 90, 180]
        
        // Find the closest target angle
        return targets.min(by: { abs($0 - angle) < abs($1 - angle) }) ?? angle
    }
    
    func jumpscareDoll() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.dollNode.isHidden = false
            self?.isDollJumpscare = true
            
            self?.cameraNode.look(at: self!.dollNode.position)
            
            self?.attachAudio(to: self!.dollNode!, audioFileName: "jumpscare1.wav", volume: 40.0, delay: 0)

            self?.attachAudio(to: self!.dollNode!, audioFileName: "doll2.wav", volume: 4.5, delay: 1.0)

            self?.attachAudio(to: self!.dollNode!, audioFileName: "whisperJumpscare.mp3", volume: 1.0, delay: 3.0)
            
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-293, 501.033, -30), duration: 0.2) {
                self?.cameraNode.look(at: self!.dollNode.position)
                // Animate zooming in by adjusting the camera's field of view
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2
                self?.cameraNode.camera?.fieldOfView = 25  // Adjust this value for closer zoom
                SCNTransaction.commit()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) { [weak self] in
            self?.cameraNode.camera?.fieldOfView = 75  // Default value for normal view

            guard let cameraNode = self?.cameraNode else { return }
            
            // Get current Euler angles and only adjust X and Z axes
            let eulerAngles = cameraNode.eulerAngles
            cameraNode.eulerAngles = SCNVector3(
                (self?.roundedAngle(eulerAngles.x * 180 / .pi) ?? 0) * .pi / 180, // Round X-axis
                eulerAngles.y, // Keep Y-axis unchanged
                (self?.roundedAngle(eulerAngles.z * 180 / .pi) ?? 0) * .pi / 180  // Round Z-axis
            )
            
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-293, 501.033, 30), duration: 1.5) {
                self?.isDollJumpscare = false
                self?.toiletDoorCloseNode.isHidden = true
                self?.toiletDoorOpenNode.isHidden = false
                self?.isJumpscareDone = true
            }
        }
    }
    
    private func addBlueFireAnimationNode() {
        // Create the fire particle system
        let fireParticleSystem = SCNParticleSystem(named: "smoothFire.scnp", inDirectory: nil)
        
        // Create a new SCNNode for the fire effect
        let fireNode = SCNNode()
        fireNode.position = transitionTriggerPosition
        
        // Attach the particle system to the fire node
        fireNode.addParticleSystem(fireParticleSystem!)
        
        scnView?.antialiasingMode = .multisampling4X // Apply anti-aliasing for smoother visuals

        // Add the fire node to the scene
        rootNode.addChildNode(fireNode)
        
        attachAudio(to: fireNode, audioFileName: "door_close.mp3", volume: 0.5, delay: 0.2)

    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume

        // Set looping for specific audio files if needed
        if audioFileName == "muffledRain.wav" || audioFileName == "pipeNecklace.mp3" || audioFileName == "pipeAfterOut.wav" {
            audioSource.loops = true
        }

        // Create a new node to attach the audio and position it
        let audioNode = SCNNode()
        node.addChildNode(audioNode)

        // Play audio with delay
        let playAudioAction = SCNAction.sequence([
            SCNAction.wait(duration: delay),
            SCNAction.playAudio(audioSource, waitForCompletion: false)
        ])
        
        // Check if this is the whisperJumpscare sound for surrounding effect
        if audioFileName == "whisperJumpscare.mp3" {
            // Define the radius of the circular path
            let radius: Float = 1.5
            let duration: TimeInterval = 4.0  // Duration for one full circle

            // Circular movement effect
            let circularMovement = SCNAction.customAction(duration: duration) { node, elapsedTime in
                let angle = Float(elapsedTime / duration) * 2 * Float.pi
                node.position = SCNVector3(radius * cos(angle), 0, radius * sin(angle))
            }
            let repeatCircularMovement = SCNAction.repeatForever(circularMovement)
            
            // Apply the circular motion action to the audioNode
            audioNode.runAction(repeatCircularMovement)
        }
        
        // Play the audio
        audioNode.runAction(playAudioAction)
    }

    @objc func examinePipe(on view: UIView) {
        isPipeFailed = false
        isPlayingPipe = true
        
        // Puzzle background setup
        pipeBackground = UIView()
        pipeBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        // Set background size
        let backgroundWidth = view.bounds.width * 0.55
        let backgroundHeight = view.bounds.height * 0.795
        
        pipeBackground?.frame = CGRect(
            x: (view.bounds.width - backgroundWidth) / 2,
            y: (view.bounds.height - backgroundHeight) / 2,
            width: backgroundWidth,
            height: backgroundHeight
        )
        pipeBackground?.layer.borderWidth = 0
        pipeBackground?.clipsToBounds = true
        view.addSubview(pipeBackground!)
        
        // INSIDE CONTENT
        // Array to hold the pipe images
        let pipeImages = (1...24).map { "pipeclue-\($0)" }
        
        // Constants for the layout
        let columns = 6
        let rows = 4
        let pipeSize: CGFloat = backgroundWidth / CGFloat(columns)  // Calculate size based on background width
        
        for (index, pieceImage) in pipeImages.enumerated() {
            guard let image = UIImage(named: pieceImage) else { continue }
            
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(
                x: CGFloat(index / rows) * pipeSize, // Column positioning
                y: CGFloat(index % rows) * pipeSize, // Row positioning
                width: pipeSize + 7.5, // Use calculated size
                height: pipeSize + 7.5  // Maintain square aspect ratio
            )
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.accessibilityIdentifier = pieceImage

            // Rotate the imageView by 90 degrees
            if pieceImage != "pipeclue-1" && pieceImage != "pipeclue-24" {
                // Random rotation angle: 0, 90, 180, or 270 degrees (in radians)
                
                var randomAngleIndex = Int.random(in: 1...3)
                
                if pieceImage == "pipeclue-2" || pieceImage == "pipeclue-11" || pieceImage == "pipeclue-22" || pieceImage == "pipeclue-23" {
                    let options = [1, 3]
                    randomAngleIndex = options.randomElement()!
                }
                
                let randomRotation = CGFloat(randomAngleIndex) * (.pi / 2) // Convert to radians
                
                imageView.transform = CGAffineTransform(rotationAngle: randomRotation)
                
                let rotationGesture = UITapGestureRecognizer(target: self, action: #selector(rotatePipePiece(_:)))
                imageView.addGestureRecognizer(rotationGesture)
            }
            
            // Apply shake animation if it's pipeclue-24
            if pieceImage == "pipeclue-24" {
                addScalingAnimation(to: imageView)
            }
            
            pipeBackground?.addSubview(imageView)
        }
        
        previouslyGreenPipes.insert("pipeclue-1")
        
        // Restart the timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        // Place the time label to the right of pipeBackground
        timeLabel = UILabel(frame: CGRect(
            x: pipeBackground!.frame.maxX + 10,  // Position to the right of pipeBackground with a small padding
            y: pipeBackground!.frame.minY / 2,       // Align vertically with the top of pipeBackground
            width: 100,                          // Set width for the label
            height: 50                           // Set height for the label
        ))
        
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.boldSystemFont(ofSize: 24) // Bigger font size
        timeLabel.textColor = .white // Changed to black for better visibility
        updateTimeLabel() // Set the initial time
        view.addSubview(timeLabel)
        
        // Start the timer
        startTimer()
        // Loop through each puzzle piece
        for i in 1...8 {
            let pipeNodeName = "pipe_\(i)"
            if let pipeNode = rootNode.childNode(withName: pipeNodeName, recursively: true) {
                // Set the category bitmask for post-processing
                pipeNode.isHidden = true
            }
        }
    }
    
    // Function to add scaling animation to a specific view
    func addScalingAnimation(to view: UIView) {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.3
        animation.fromValue = 1.0
        animation.toValue = 1.2  // Scale up to 120%
        animation.autoreverses = true
        animation.repeatCount = Float.greatestFiniteMagnitude
        view.layer.add(animation, forKey: "scaling")
    }

    @objc func rotatePipePiece(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView,
              let pipeName = imageView.accessibilityIdentifier else {
            return
        }
        
        // Check if the pipe is already green
        if previouslyGreenPipes.contains(pipeName) {
            print("\(pipeName) is already green and cannot be rotated anymore.")
            return // Exit early if the pipe is already green
        }
        
        // Rotate the imageView by 90 degrees
        UIView.animate(withDuration: 0.2) {
            imageView.transform = imageView.transform.rotated(by: .pi / 2)
        }
        
        // Check if the piece has reached the correct rotation
        let currentRotation = atan2(imageView.transform.b, imageView.transform.a)
        let tolerance: CGFloat = 0.01
        
        // Define which pipes have two correct rotations (0 and .pi)
        let pipesWithTwoRotations: Set<String> = ["pipeclue-2", "pipeclue-11", "pipeclue-22", "pipeclue-23"]
        
        // Check if the rotation matches one of the correct rotations
        let isCorrectRotation: Bool
        if pipesWithTwoRotations.contains(pipeName) {
            isCorrectRotation = abs(currentRotation - 0) < tolerance || abs(currentRotation - .pi) < tolerance
        } else {
            isCorrectRotation = abs(currentRotation - 0) < tolerance
        }
        
        // Handle the special pieces (2, 22, 23) to reverse wipe direction at 180 degrees
        if abs(currentRotation - .pi) < tolerance, ["pipeclue-2", "pipeclue-11", "pipeclue-22", "pipeclue-23"].contains(pipeName) {
            // Reverse the wipe direction if rotation is 180 degrees
            if let currentDirection = wipeDirections[pipeName] {
                wipeDirections[pipeName] = (currentDirection == "up" || currentDirection == "down") ? (currentDirection == "up" ? "down" : "up") : (currentDirection == "left" ? "right" : "left")
                print("Wipe direction for \(pipeName) is now \(wipeDirections[pipeName] ?? "unknown")")
            }
        }
        
        if isCorrectRotation {
            print("\(pipeName) is correctly rotated.")
            
            // Check if this pipe is the next in the fixed sequence
            if let index = fixedPipeSequence.firstIndex(of: pipeName) {
                correctlyRotatedPipes.append(pipeName)
                
                // Check if the index is the next in the sequence
                if index == lastActivatedPipeIndex + 1 {
                    lastActivatedPipeIndex = index // Update last activated index
                }
                
                if correctlyRotatedPipes.count >= 15 {
                    attachAudio(to: rootNode, audioFileName: "waterNecklacePipe.mp3", volume: 1.3, delay: 0)
                    
                    for correctPipes in correctlyRotatedPipes {
                        previouslyGreenPipes.insert(correctPipes)
                    }
                    
                    correctlyRotatedPipes.append("pipeclue-24")
                    // Start the animation sequence
                    animateNextPipe(pipes: Array(correctlyRotatedPipes))
                }
            }
        } else {
            print("\(pipeName) is not in the correct rotation.")
            if let index = correctlyRotatedPipes.firstIndex(of: pipeName) {
                correctlyRotatedPipes.remove(at: index)
                revertPipeToOriginal(pipeName: pipeName) // Revert to original appearance
            }
        }
        
        attachAudio(to: rootNode, audioFileName: "pipeMove.mp3", volume: 0.8, delay: 0)
        
        print(correctlyRotatedPipes.count)

    }
    
    // Function to animate the next pipe
    private func animateNextPipe(pipes: [String]) {
        timeLabel.removeFromSuperview()
        
        // Ensure we haven't animated all pipes
        guard currentPipeIndex < pipes.count else { return }
        
        let pipeName = pipes[currentPipeIndex]
        guard let subview = pipeBackground?.subviews.first(where: {
            $0.accessibilityIdentifier == pipeName
        }) as? UIImageView else {
            currentPipeIndex += 1 // Move to the next pipe if this one is not found
            animateNextPipe(pipes: pipes) // Continue to the next pipe
            return
        }
        
        // Ensure the pipe is rotated correctly
        let currentRotation = atan2(subview.transform.b, subview.transform.a)
        let tolerance: CGFloat = 0.01
        
        // Only turn green if it meets the rotation criteria and is part of the correct sequence
        // Define which pipes have two correct rotations (0 and .pi)
        let pipesWithTwoRotations: Set<String> = ["pipeclue-2", "pipeclue-11", "pipeclue-22", "pipeclue-23"]
        
        // Check if the rotation matches one of the correct rotations
        let isCorrectRotation: Bool
        if pipesWithTwoRotations.contains(pipeName) {
            isCorrectRotation = abs(currentRotation - 0) < tolerance || abs(currentRotation - .pi) < tolerance
        } else {
            isCorrectRotation = abs(currentRotation - 0) < tolerance
        }
        
        if isCorrectRotation {
            animatePipeToGreen(pipeName: pipeName)
            // Use a timer to call animateNextPipe after the duration of the animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Adjust this duration as needed
                self.currentPipeIndex += 1 // Move to the next pipe
                self.animateNextPipe(pipes: pipes) // Call the next pipe animation
            }
        } else {
            // If not correct, continue to the next pipe
            currentPipeIndex += 1
            animateNextPipe(pipes: pipes) // Continue to the next pipe
        }
        print("Current pipe index after animation: \(currentPipeIndex)")
        
        if areAllPipesCorrectlyRotated() {
            pipeCompleted()
        }
    }
    
    // Modify animatePipeToGreen to accept a wipe direction
    func animatePipeToGreen(pipeName: String) {
        guard let subview = pipeBackground?.subviews.first(where: {
            $0.accessibilityIdentifier == pipeName
        }) as? UIImageView else { return }
        
        let greenImageName = pipeName.replacingOccurrences(of: "pipeclue", with: "pipegreen")
        guard let greenImage = UIImage(named: greenImageName) else { return }
        
        // Create a new UIImageView for the green image
        let greenImageView = UIImageView(image: greenImage)
        greenImageView.frame = subview.bounds
        greenImageView.contentMode = .scaleAspectFill
        greenImageView.clipsToBounds = true
        
        // Add the green image view on top of the original image view
        subview.addSubview(greenImageView)
        
        // Create a mask layer for the wipe effect
        let maskLayer = CALayer()
        
        // Get the wipe direction for the current pipe
        let wipeDirection = wipeDirections[pipeName] ?? "down" // Default to "up" if not found
        
        // Animate the wipe effect based on the direction
        let wipeDuration: TimeInterval = 0.6
        let finalHeight: CGFloat = greenImageView.bounds.height * 2
        let finalWidth: CGFloat = greenImageView.bounds.width * 2
        
        switch wipeDirection {
        case "up":
            maskLayer.frame = CGRect(x: 0, y: 0, width: greenImageView.bounds.width, height: finalHeight)
            maskLayer.backgroundColor = UIColor.black.cgColor
            greenImageView.layer.mask = maskLayer
            
            let upAnimation = CABasicAnimation(keyPath: "bounds.size.height")
            upAnimation.fromValue = 0
            upAnimation.toValue = finalHeight
            upAnimation.duration = wipeDuration
            upAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            maskLayer.add(upAnimation, forKey: "wipeUp")
            
        case "down":
            maskLayer.frame = CGRect(x: 0, y: 0, width: greenImageView.bounds.width, height: 0) // Start with height 0
            maskLayer.backgroundColor = UIColor.black.cgColor
            greenImageView.layer.mask = maskLayer
            
            let downAnimation = CABasicAnimation(keyPath: "bounds.size.height")
            downAnimation.fromValue = 0
            downAnimation.toValue = finalHeight
            downAnimation.duration = wipeDuration
            downAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            maskLayer.add(downAnimation, forKey: "wipeDown")
            
        case "right":
            maskLayer.frame = CGRect(x: 0, y: 0, width: 0, height: greenImageView.bounds.height)
            maskLayer.backgroundColor = UIColor.black.cgColor
            greenImageView.layer.mask = maskLayer
            
            let leftAnimation = CABasicAnimation(keyPath: "bounds.size.width")
            leftAnimation.fromValue = 0
            leftAnimation.toValue = finalWidth
            leftAnimation.duration = wipeDuration
            leftAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            maskLayer.add(leftAnimation, forKey: "wipeRight")
            
        default:
            break
        }
        
        // Update the mask layer's height to the final height
        maskLayer.bounds.size.height = finalHeight
        
        // After the wipe animation, immediately update the subview's image
        DispatchQueue.main.asyncAfter(deadline: .now() + wipeDuration) {
            subview.image = greenImage // Change the image to green
            greenImageView.removeFromSuperview() // Remove the green image view
        }
    }
    
    func revertPipeToOriginal(pipeName: String) {
        guard let subview = pipeBackground?.subviews.first(where: {
            $0.accessibilityIdentifier == pipeName
        }) as? UIImageView else { return }
        
        subview.image = UIImage(named: pipeName)
    }
    
    func areAllPipesCorrectlyRotated() -> Bool {
        // Only check specific pipes for correct rotation
        for pipeName in wipeDirections.keys {
            guard let subview = pipeBackground?.subviews.first(where: {
                $0.accessibilityIdentifier == pipeName
            }) as? UIImageView else {
                continue
            }
            
            // Check rotation of the specified piece
            let currentRotation = atan2(subview.transform.b, subview.transform.a)
            let tolerance: CGFloat = 0.01
            // Define which pipes have two correct rotations (0 and .pi)
            let pipesWithTwoRotations: Set<String> = ["pipeclue-2", "pipeclue-11", "pipeclue-22", "pipeclue-23"]
            
            // Check if the rotation matches one of the correct rotations
            let isCorrectRotation: Bool
            
            if pipesWithTwoRotations.contains(pipeName) {
                isCorrectRotation = abs(currentRotation - 0) < tolerance || abs(currentRotation - .pi) < tolerance
            } else {
                isCorrectRotation = abs(currentRotation - 0) < tolerance
            }
            
            if !isCorrectRotation {
                return false
            }
        }
        
        return true // All specified pieces are correctly rotated
    }
    
    func animateNecklaceFalling(from pipeNode: SCNNode) {
        let moveLeft = SCNAction.moveBy(x: 10.0, y: 0, z: 0, duration: 1.5) // Adjust the x-offset and duration as needed
        // Define the falling action
        let fallDown = SCNAction.moveBy(x: 0, y: 0, z: -50.0, duration: 3.0) // Adjust the Y-offset and duration as needed
        let playSound = SCNAction.playAudio(SCNAudioSource(fileNamed: "fallingNecklace.mp3")!, waitForCompletion: false) // Add a sound effect for dropping the necklace
        let sequence = SCNAction.sequence([moveLeft, fallDown, playSound])
        
        // Run the action
        necklaceNode.runAction(sequence)
        
        attachAudio(to: playerEntity.playerNode!, audioFileName: "s8-andra4.mp3", volume: 5, delay: 0)
    }
            
    func updateProximityAndGlow(interactButton: UIButton) {
        guard let playerNode = playerEntity.playerNode, let cluePipeNode = cluePipeNode, let clueCabinetNode = clueCabinetNode else {
            print("Error: Player node or Cake node not found")
            return
        }
        
        // Measure distances to each clue object
        let distanceToCabinet = playerNode.position.distance(to: clueCabinetNode.position)
        let distanceToPipe = playerNode.position.distance(to: cluePipeNode.position)
        
        if !isCabinetOpened {
            if distanceToCabinet < proximityDistance {
                // If the pipe is closer
                toggleGlowEffect(on: clueCabinetNode, isEnabled: true)
                toggleGlowEffect(on: cluePipeNode, isEnabled: false)
                
                // Update interact button content
                interactButton.setTitle("Open Cabinet", for: .normal)
                interactButton.isHidden = false
            } else {
                // If neither is within proximity, turn off all glows and hide the button
                toggleGlowEffect(on: clueCabinetNode, isEnabled: false)
                toggleGlowEffect(on: cluePipeNode, isEnabled: false)
                
                interactButton.isHidden = true
            }
        } else if isNecklaceObtained {
            // If neither is within proximity, turn off all glows and hide the button
            toggleGlowEffect(on: clueCabinetNode, isEnabled: false)
            toggleGlowEffect(on: cluePipeNode, isEnabled: false)
            
            interactButton.isHidden = true
            GameViewController.joystickComponent.joystickView.isHidden = false
        } else {
            if distanceToPipe < proximityDistance {
                toggleGlowEffect(on: cluePipeNode, isEnabled: true)
                toggleGlowEffect(on: clueCabinetNode, isEnabled: false)

                // Update interact button content
                interactButton.setTitle("Examine Pipe", for: .normal)
                interactButton.isHidden = false
            } else {
                // If neither is within proximity, turn off all glows and hide the button
                toggleGlowEffect(on: clueCabinetNode, isEnabled: false)
                toggleGlowEffect(on: cluePipeNode, isEnabled: false)
                
                interactButton.isHidden = true
            }
        }
    }
    
    func toggleGlowEffect(on node: SCNNode, isEnabled: Bool) {
        if isEnabled {
            node.categoryBitMask = 2 // Enable glow effect for the specified node

            if node == clueCabinetNode! {
                let cabinetNodeName = "smallCabinetDoor"
                if let cabinetNode = rootNode.childNode(withName: cabinetNodeName, recursively: true) {
                    // Set the category bitmask for post-processing
                    cabinetNode.categoryBitMask = 2
                }
            } else {
                // Loop through each puzzle piece
                for i in 2...8 {
                    let pipeNodeName = "pipe_\(i)"
                    if let pipeNode = rootNode.childNode(withName: pipeNodeName, recursively: true) {
                        // Set the category bitmask for post-processing
                        pipeNode.categoryBitMask = 2
                    }
                }
            }
        } else {
            // Disable the technique
            scnView?.technique = nil
            node.categoryBitMask = 1 // Disable glow effect for the specified node
            
            if node == clueCabinetNode! {
                let cabinetNodeName = "smallCabinetDoor"
                if let cabinetNode = rootNode.childNode(withName: cabinetNodeName, recursively: true) {
                    // Set the category bitmask for post-processing
                    cabinetNode.categoryBitMask = 1
                }
            } else {
                // Loop through each puzzle piece
                for i in 2...8 {
                    let pipeNodeName = "pipe_\(i)"
                    if let pipeNode = rootNode.childNode(withName: pipeNodeName, recursively: true) {
                        // Set the category bitmask for post-processing
                        pipeNode.categoryBitMask = 1
                    }
                }
            }
        }
    }
    
    @objc func openCabinet() {
        // Your existing code for opening the cabinet
        isCabinetOpened = true
        GameViewController.joystickComponent.joystickView.isHidden = true

        attachAudio(to: playerEntity.playerNode!, audioFileName: "s8-andra2.mp3", volume: 5, delay: 4)
        
        DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-402.985, 501, 30.0), duration: 2.5) {
                guard let cameraNode = self?.cameraNode else { return }
                
                // Get current Euler angles and only adjust X and Z axes
                let eulerAngles = cameraNode.eulerAngles
                cameraNode.eulerAngles = SCNVector3(
                    (self?.roundedAngle(eulerAngles.x * 180 / .pi) ?? 0) * .pi / 180, // Round X-axis
                    eulerAngles.y, // Keep Y-axis unchanged
                    (self?.roundedAngle(eulerAngles.z * 180 / .pi) ?? 0) * .pi / 180  // Round Z-axis
                )
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 2.0
                self?.cameraNode.camera?.fieldOfView = 50  // Adjust this value for closer zoom
                SCNTransaction.commit()
                
                self?.cameraNode.look(at: self!.clueCabinetNode.position)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
            self.cameraNode.camera?.fieldOfView = 75  // Adjust this value for closer zoom

            guard let cameraNode = self.cameraNode else { return }
            
            // Get current Euler angles and only adjust X and Z axes
            let eulerAngles = cameraNode.eulerAngles
            cameraNode.eulerAngles = SCNVector3(
                (self.roundedAngle(eulerAngles.x * 180 / .pi) ?? 0) * .pi / 180, // Round X-axis
                eulerAngles.y, // Keep Y-axis unchanged
                (self.roundedAngle(eulerAngles.z * 180 / .pi) ?? 0) * .pi / 180  // Round Z-axis
            )
            
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-376.371, 516, 30.0), duration: 2.0) {
                self.isCabinetDone = true
                GameViewController.joystickComponent.joystickView.isHidden = false
                self.attachAudio(to: self.cluePipeNode, audioFileName: "pipeNecklace.mp3", volume: 1.0, delay: 0)
                self.attachAudio(to: self.playerEntity.playerNode!, audioFileName: "s8-andra3.mp3", volume: 5, delay: 2)
            }
        }
    }
    
    func startTimer() {
        applyCustomFont(to: timeLabel, fontSize: 24)
        
        timer?.invalidate() // Reset any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime() {
        timeLimit -= 1
        updateTimeLabel()
                
        if timeLimit <= 0 {
            timer?.invalidate()
        }
    }
    
    func updateTimeLabel() {
        if timeLimit > 0 {
            let minutes = timeLimit / 60
            let seconds = timeLimit % 60
            timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
        } else {
            timeLabel.text = "Time's Up!"
            triggerPipeFailedTransition() // Implement your failure transition logic here
        }
    }
    
    func triggerPipeFailedTransition() {
        print("Puzzle failed!")
        
        pipeBackground?.removeFromSuperview()
        timeLabel.removeFromSuperview()
        // Invalidate the existing timer if it's running
        timer?.invalidate()
        
        // Reset the time limit to the starting value
        timeLimit = 35 // Set this to the initial time limit you want
        
        // Loop through each puzzle piece
        for i in 1...8 {
            let pipeNodeName = "pipe_\(i)"
            if let pipeNode = rootNode.childNode(withName: pipeNodeName, recursively: true) {
                // Set the category bitmask for post-processing
                pipeNode.isHidden = false
            }
        }

        isNecklaceObtained = false
        isPlayingPipe = false
        isPipeFailed = true
        currentPipeIndex = 0
        correctRotationCounter = 0  // Counter to track correct rotations
        correctlyRotatedPipes = []
        previouslyGreenPipes = []  // Track pipes that were previously green
        lastActivatedPipeIndex = -1 // Track the last activated pipe index
    }
    
    func displayNecklaceObtainedLabel(on view: UIView) {
        necklaceLabel.text = isNecklaceObtained ? "Kirana's necklace is obtained" : "You failed! Try again."
        view.addSubview(necklaceLabel)
        
        // Position the camera instruction label above the center of the screen
        let offsetFromTop: CGFloat = 170
        necklaceLabel.frame = CGRect(
            x: (view.bounds.width - 250) / 2,
            y: (view.bounds.height) / 2 - offsetFromTop,
            width: 255,
            height: 25
        )
        // Fade in the label
        UIView.animate(withDuration: 0.5) {
            self.necklaceLabel.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 0.5) {
                self.necklaceLabel.alpha = 0.0
            }
        }
    }
        
    // Apply the custom font to a label
    private func applyCustomFont(to label: UILabel, fontSize: CGFloat) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: fontSize) {
            label.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
    }
    
    // Check if the player is close to the transition trigger point
    func checkProximityToTransition() -> Bool {
        guard let playerNode = playerEntity.playerNode else { return false }
        
        // Calculate the distance to the transition trigger
        let distance = playerNode.position.distance(to: transitionTriggerPosition)
        print("player position:", playerNode.position)
        print("distance to trigger:", distance)
        
        return distance < triggerDistance
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}

