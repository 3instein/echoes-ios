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

    weak var scnView: SCNView?
    var playButton: UIButton?  // Store a reference to the play button
    var clueCabinetNode: SCNNode!
    var cluePipeNode: SCNNode!
    
    var hasKey = true  // Track if the player has the key
    var isCabinetOpened = false  // Track if the player has the key
    var isPlayingPipe = false  // Track if the player has the key
    
    let proximityDistance: Float = 100.0  // Define a proximity distance
    
    var pipeBackground: UIView?
    var isNecklaceObtained: Bool = false  // Track if the game is completed
    
    var timer: Timer?
    var timeLimit: Int = 60
    var timeLabel: UILabel?
    
    var isPipeClicked = false
    
    var rotatingPipeNode: SCNNode?  // Node for the rotating pipe
    
    let wipeDirections: [String: String] = [
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
    
    var transitionTriggerPosition = SCNVector3(2602, 559, 45)
    var triggerDistance: Float = 100
    
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

    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()
        
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
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
                attachAudio(to: andraNode, audioFileName: "s8-andra1.mp3", volume: 500, delay: 5)
            }
        }
        
        if let pipeNode = rootNode.childNode(withName: "pipe", recursively: true) {
            attachAudio(to: pipeNode, audioFileName: "pipeNecklace.mp3", volume: 0.3, delay: 2)
        }
        
        clueCabinetNode = rootNode.childNode(withName: "smallCabinet", recursively: true)
        
        cluePipeNode = rootNode.childNode(withName: "pipe", recursively: true)
        
        necklaceNode = rootNode.childNode(withName: "necklace", recursively: true)

        self.physicsWorld.contactDelegate = self
    }
    
    func animateNecklaceFalling(from pipeNode: SCNNode) {
        // Define the falling action
        let fallDown = SCNAction.moveBy(x: 0, y: 0, z: -70.0, duration: 3.0) // Adjust the Y-offset and duration as needed
        let wait = SCNAction.wait(duration: 3) // Optional wait time before the next action
        let playSound = SCNAction.playAudio(SCNAudioSource(fileNamed: "fallingNecklaceWater.mp3")!, waitForCompletion: true) // Add a sound effect for dropping the necklace
        let sequence = SCNAction.sequence([fallDown, wait, playSound])

        // Run the action
        necklaceNode.runAction(sequence)
    }

    func pipeCompleted() {
        if currentPipeIndex == 15 {
            print("Puzzle solved! The necklace is revealed.")
            
            pipeBackground?.removeFromSuperview()
            timeLabel?.removeFromSuperview()
            timer?.invalidate()
            cluePipeNode.isHidden = false
            // Set game completion flag to true
            isNecklaceObtained = true
            
            // Delay to wait until the necklace finishes falling
            DispatchQueue.main.asyncAfter(deadline: .now()) { [weak self] in
                GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-235.327, 186.952, 0), duration: 2.0) {
                    self?.cameraNode.look(at: self!.necklaceNode.position)
                    self?.animateNecklaceFalling(from: self!.cluePipeNode!)
                    self?.isPlayingPipe = false
                }
            }
        }
    }

    @objc func examinePipe(on view: UIView) {
        isPlayingPipe = true
        
        // Puzzle background setup
        pipeBackground = UIView()
        pipeBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        // Set background size
        let backgroundWidth = view.bounds.width * 0.55
        let backgroundHeight = view.bounds.height * 0.795
        
        pipeBackground?.frame = CGRect(
            x: (view.bounds.width - backgroundWidth) / 2,
            y: (view.bounds.height - backgroundHeight) / 2 + 20,
            width: backgroundWidth,
            height: backgroundHeight
        )
        pipeBackground?.layer.cornerRadius = 20
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
                
                if pieceImage == "pipeclue-2" || pieceImage == "pipeclue-22" || pieceImage == "pipeclue-23" {
                    let options = [1, 3]
                    randomAngleIndex = options.randomElement()!
                }
                
                let randomRotation = CGFloat(randomAngleIndex) * (.pi / 2) // Convert to radians
                
                imageView.transform = CGAffineTransform(rotationAngle: randomRotation)
                
                let rotationGesture = UITapGestureRecognizer(target: self, action: #selector(rotatePipePiece(_:)))
                imageView.addGestureRecognizer(rotationGesture)
            }
            
            pipeBackground?.addSubview(imageView)
        }
        
        previouslyGreenPipes.insert("pipeclue-1")
        //        animatePipeToGreen(pipeName: "pipeclue-1")
        
        // Add time label to the top of the white box
        timeLabel = UILabel(frame: CGRect(
            x: pipeBackground!.frame.minX,
            y: pipeBackground!.frame.minY - 60, // Position slightly above the white box
            width: backgroundWidth,
            height: 50
        ))
        
        timeLabel?.textAlignment = .center
        timeLabel?.font = UIFont.boldSystemFont(ofSize: 24) // Bigger font size
        timeLabel?.textColor = .white // Changed to black for better visibility
        updateTimeLabel() // Set the initial time
        view.addSubview(timeLabel!)
        
        // Start the timer
        startTimer()
        cluePipeNode.isHidden = true
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
        let pipesWithTwoRotations: Set<String> = ["pipeclue-2", "pipeclue-22", "pipeclue-23"]
        
        // Check if the rotation matches one of the correct rotations
        let isCorrectRotation: Bool
        if pipesWithTwoRotations.contains(pipeName) {
            isCorrectRotation = abs(currentRotation - 0) < tolerance || abs(currentRotation - .pi) < tolerance
        } else {
            isCorrectRotation = abs(currentRotation - 0) < tolerance
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
                
//        print(correctlyRotatedPipes.count)
    }
        
    // Function to animate the next pipe
    private func animateNextPipe(pipes: [String]) {
        timeLabel?.removeFromSuperview()

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
        let pipesWithTwoRotations: Set<String> = ["pipeclue-2", "pipeclue-22", "pipeclue-23"]
        
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
            let pipesWithTwoRotations: Set<String> = ["pipeclue-2", "pipeclue-22", "pipeclue-23"]
            
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
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        audioSource.isPositional = true
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume
        
        // Set looping for continuous rain sound
        if audioFileName == "muffledRain.wav" || audioFileName == "pipeNecklace.mp3" {
            audioSource.loops = true  // This ensures the rain loops without breaking
        }
        
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        let waitAction = SCNAction.wait(duration: delay)
        
        let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
        node.runAction(sequenceAction)
    }

    
    func updateProximityAndGlow(interactButton: UIButton) {
        guard let playerNode = playerEntity.playerNode else {
            print("Error: Player node not found")
            return
        }
        
        // Measure distances to each clue object
        let distanceToCabinet = playerNode.position.distance(to: clueCabinetNode.position)
        let distanceToPipe = playerNode.position.distance(to: cluePipeNode.position)
        
        if isNecklaceObtained {
            if distanceToCabinet < proximityDistance {
                toggleGlowEffect(on: clueCabinetNode, isEnabled: true)
                toggleGlowEffect(on: cluePipeNode, isEnabled: false)

                // Update interact button content
                interactButton.setTitle("Open Cabinet", for: .normal)
                interactButton.isHidden = false
            }
            else {
                // If neither is within proximity, turn off all glows and hide the button
                toggleGlowEffect(on: clueCabinetNode, isEnabled: false)
                toggleGlowEffect(on: cluePipeNode, isEnabled: false)
                interactButton.isHidden = true
            }
        } else {
            // Determine which object is closer and within the proximity distance
            if distanceToCabinet < proximityDistance && distanceToCabinet < distanceToPipe {
                // If the cabinet is closer
                toggleGlowEffect(on: clueCabinetNode, isEnabled: true)
                toggleGlowEffect(on: cluePipeNode, isEnabled: false)
                
                // Update interact button content
                interactButton.setTitle("Open Cabinet", for: .normal)
                interactButton.isHidden = false
            } else if distanceToPipe < proximityDistance {
                // If the pipe is closer
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
        } else {
            node.categoryBitMask = 1 // Disable glow effect for the specified node
        }
    }
    
    @objc func openCabinet() {
        // Your existing code for opening the cabinet
        isCabinetOpened = true
        attachAudio(to: clueCabinetNode!, audioFileName: "toiletOpenCabinet.mp3", volume: 50, delay: 0)
        attachAudio(to: playerEntity.playerNode!, audioFileName: "s8-andra2.mp3", volume: 50, delay: 5)
        
        // code bwh buat suarae yg opencabinet ilang soale d hide
        //        clueCabinetNode.isHidden = true
    }
    
    func startTimer() {
        timer?.invalidate() // Reset any existing timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime() {
        timeLimit -= 1
        updateTimeLabel()
        
        checkGameEnd() // Check if the game should end
        
        if timeLimit <= 0 {
            timer?.invalidate()
        }
    }
    
    func updateTimeLabel() {
        if timeLimit > 0 {
            let minutes = timeLimit / 60
            let seconds = timeLimit % 60
            timeLabel?.text = String(format: "%02d:%02d", minutes, seconds)
        } else {
            timeLabel?.text = "Time's Up!"
            timeOut()
        }
    }
    
    func timeOut() {
        print("You failed!")
        // Show failure transition here
        triggerPipeFailedTransition() // Implement your failure transition logic here
        
        // Create a temporary UITapGestureRecognizer
        let tapGesture = UITapGestureRecognizer()
//        dismissPipe(tapGesture) // Dismiss the puzzle using the temporary gesture recognizer
    }
    
    func triggerPipeFailedTransition() {
        isNecklaceObtained = true
        pipeBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        guard let superview = pipeBackground?.superview else { return }
        
        // Get the center of the screen
        let screenCenter = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
        
        timeLabel?.isHidden = true
        
        // Create an imageView for the completed puzzle image
        let fullPipeImageView = UIImageView(image: UIImage(named: "failed card.png"))
        fullPipeImageView.frame.size = CGSize(width: 450, height: 350)
        fullPipeImageView.contentMode = .scaleAspectFit
        fullPipeImageView.alpha = 0  // Start with hidden image
        superview.addSubview(fullPipeImageView)
        
        // Animate each piece to the center of the screen
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            for piece in self.pipeBackground?.subviews ?? [] {
                if let imageView = piece as? UIImageView {
                    imageView.center = screenCenter  // Move each piece to the center
                    imageView.alpha = 0  // Fade out the pieces
                }
            }
        }, completion: { _ in
            // Remove all individual pieces from the view after animation
            for piece in self.pipeBackground?.subviews ?? [] {
                if let imageView = piece as? UIImageView {
                    imageView.removeFromSuperview()
                }
            }
            
            // Set initial properties for the fullPuzzleImageView
            fullPipeImageView.alpha = 0  // Start with the image hidden
            fullPipeImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)  // Start small
            
            // Center the image on the screen
            fullPipeImageView.center = screenCenter
            
            // Fade in the full puzzle image after the pieces are removed
            UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                fullPipeImageView.alpha = 1
                fullPipeImageView.transform = CGAffineTransform.identity
            })
        })
    }
    
    func checkGameEnd() {
        if timeLimit <= 0 {
            // Call the function to handle game failure if time runs out
            timeOut()
            //            triggerPuzzleFailedTransition()
        } else if isNecklaceObtained {
            // Call the function to handle successful completion
            //            triggerPuzzleCompletionTransition()
        }
    }
        
    // Check if the player is close to the transition trigger point
    func checkProximityToTransition() -> Bool {
        guard let playerPosition = playerEntity.playerNode?.position else { return false }
        let distance = playerPosition.distance(to: transitionTriggerPosition)
        print("player:", playerPosition)
        print("distance:", distance)
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

