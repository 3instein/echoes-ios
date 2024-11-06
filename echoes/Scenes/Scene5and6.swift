import SceneKit
import UIKit

//TAMBAHIN NODE doorClose & doorOpen, sesuaiin api sama titik di depan kamar, tambahin node "doll" di file .scn
class Scene5and6: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var doorCloseNode: SCNNode!
    var doorOpenNode: SCNNode!
    var grandmaNode: SCNNode!
    var dollNode: SCNNode!
    
    var combinedPieces: [UIView: [UIView]] = [:]  // Dictionary that tracks combined pieces
    var completedCombinations: [[UIView]] = []  // Track completed combinations
    
    var objCakeNode: SCNNode!  // Add a reference for Obj_Cake_003
    let proximityDistance: Float = 180.0  // Define a proximity distance
    
    weak var scnView: SCNView?
    var puzzleBackground: UIView?
    var playButton: UIButton?  // Store a reference to the play button
    
    var isPlayingPuzzle: Bool = false
    var isPhotoObtained: Bool = false  // Track if the game is completed
    var isCodeDone: Bool = false  // Track if the game is completed
    var isJumpscareDone: Bool = false

    let snapDistance: CGFloat = 45.0
    
    var timer: Timer?
    var timeLimit: Int = 210 // 5-minute timer
    private var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.alpha = 0.0
        return label
    }()
    
    var hasGroupedTwoPieces = false  // Track if two pieces have been grouped
    var currentCombination: [UIView] = [] // Initialize currentCombination if not already done
    
    let neighbors: [String: [String: CGPoint]] = [
        "puzzle_piece_1.png": ["puzzle_piece_2.png": CGPoint(x: 30, y: -20), "puzzle_piece_9.png": CGPoint(x: 20, y: 45)],
        "puzzle_piece_2.png": ["puzzle_piece_1.png": CGPoint(x: -30, y: 20), "puzzle_piece_3.png": CGPoint(x: 20, y: 20)],
        "puzzle_piece_3.png": ["puzzle_piece_2.png": CGPoint(x: -20, y: -20), "puzzle_piece_4.png": CGPoint(x: 35, y: -10), "puzzle_piece_9.png": CGPoint(x: -40, y: 40)],
        "puzzle_piece_4.png": ["puzzle_piece_3.png": CGPoint(x: -35, y: 10), "puzzle_piece_5.png": CGPoint(x: 40, y: 5), "puzzle_piece_10.png": CGPoint(x: -15, y: 55)],
        "puzzle_piece_5.png": ["puzzle_piece_4.png": CGPoint(x: -40, y: -5), "puzzle_piece_6.png": CGPoint(x: 21, y: -10), "puzzle_piece_7.png": CGPoint(x: 40, y: 40)],
        "puzzle_piece_6.png": ["puzzle_piece_5.png": CGPoint(x: -21, y: 10), "puzzle_piece_7.png": CGPoint(x: 25, y: 42), "puzzle_piece_8.png": CGPoint(x: 53, y: 5)],
        "puzzle_piece_7.png": ["puzzle_piece_5.png": CGPoint(x: -40, y: -40), "puzzle_piece_6.png": CGPoint(x: -25, y: -42)],
        "puzzle_piece_8.png": ["puzzle_piece_6.png": CGPoint(x: -53, y: -5), "puzzle_piece_12.png": CGPoint(x: 5, y: 70)],
        "puzzle_piece_9.png": ["puzzle_piece_1.png": CGPoint(x: -20, y: -45), "puzzle_piece_3.png": CGPoint(x: 40, y: -40), "puzzle_piece_13.png": CGPoint(x: 0, y: 30)],
        "puzzle_piece_10.png": ["puzzle_piece_4.png": CGPoint(x: 15, y: -55), "puzzle_piece_11.png": CGPoint(x: 60, y: 0), "puzzle_piece_14.png": CGPoint(x: 0, y: 50), "puzzle_piece_15.png": CGPoint(x: 35, y: 50)],
        "puzzle_piece_11.png": ["puzzle_piece_10.png": CGPoint(x: -60, y: 0), "puzzle_piece_15.png": CGPoint(x: -15, y: 40), "puzzle_piece_16.png": CGPoint(x: 45, y: 40)],
        "puzzle_piece_12.png": ["puzzle_piece_8.png": CGPoint(x: -5, y: -70), "puzzle_piece_16.png": CGPoint(x: -20, y: 20)],
        "puzzle_piece_13.png": ["puzzle_piece_9.png": CGPoint(x: -0, y: -30), "puzzle_piece_14.png": CGPoint(x: 45, y: 20), "puzzle_piece_17.png": CGPoint(x: 75, y: 30)],
        "puzzle_piece_14.png": ["puzzle_piece_10.png": CGPoint(x: 0, y: -50), "puzzle_piece_13.png": CGPoint(x: -45, y: -20), "puzzle_piece_15.png": CGPoint(x: 45, y: 0), "puzzle_piece_17.png": CGPoint(x: 30, y: 25)],
        "puzzle_piece_15.png": ["puzzle_piece_14.png": CGPoint(x: -45, y: 0), "puzzle_piece_10.png": CGPoint(x: -35, y: -50), "puzzle_piece_11.png": CGPoint(x: 15, y: -40)],
        "puzzle_piece_16.png": ["puzzle_piece_11.png": CGPoint(x: -45, y: -40), "puzzle_piece_12.png": CGPoint(x: 20, y: -20)],
        "puzzle_piece_17.png": ["puzzle_piece_13.png": CGPoint(x: -75, y: -30), "puzzle_piece_14.png": CGPoint(x: -30, y: -25)]
    ]
    
    // Define the label for displaying the message
    private let puzzleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.alpha = 0.0
        return label
    }()
    
    var isPuzzleFailed = false
    
    var isDollJumpscare = false
    
    //GANTI LAGI KE TITIK DI DEPAN KAMAR KIRANA
    let transitionTriggerPosition = SCNVector3(-475.2, -888.827, -1.377)
    let triggerDistance: Float = 80.0
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene5and6.scn") else {
            print("Warning: House scene 'Scene5and6.scn' not found")
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
        cameraNode.camera?.automaticallyAdjustsZRange = true
        
        // Add the camera component to handle the camera logic
        cameraComponent = CameraComponent(cameraNode: cameraNode)
        
        rootNode.addChildNode(lightNode)
        
        // Find Obj_Cake_003 node in the scene
        objCakeNode = rootNode.childNode(withName: "Puzzle_1", recursively: true)
        
        doorOpenNode = rootNode.childNode(withName: "doorOpen", recursively: true)
        doorCloseNode = rootNode.childNode(withName: "doorClose", recursively: true)
        
        grandmaNode = rootNode.childNode(withName: "grandma", recursively: true)
        dollNode = rootNode.childNode(withName: "doll", recursively: true)
        
        if let doorNode = rootNode.childNode(withName: "doorFamilyRoom", recursively: true) {
            attachAudio(to: doorNode, audioFileName: "door_close.mp3", volume: 3, delay: 0)
        }
        
        if let woodNode = rootNode.childNode(withName: "woodenFloor", recursively: false) {
            attachAudio(to: woodNode, audioFileName: "woodenFloor.wav", volume: 0.7, delay: 0)
        }
        
        if let clockNode = rootNode.childNode(withName: "clockTicking", recursively: true) {
            attachAudio(to: clockNode, audioFileName: "clockTicking.wav", volume: 0.7, delay: 0)
        }
        
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 0.7, delay: 0)
        }
                
        if let grandmaParentNode = rootNode.childNode(withName: "grandma", recursively: true) {
            if let grandmaNode1 = grandmaParentNode.childNode(withName: "s5-grandma", recursively: false) {
                attachAudio(to: grandmaNode1, audioFileName: "s5-grandma.wav", volume: 8, delay: 6)
            }
        }
         
        if let andraParentNode = rootNode.childNode(withName: "player", recursively: true) {
            if let andraNode = andraParentNode.childNode(withName: "s5-andra", recursively: false) {
                attachAudio(to: andraNode, audioFileName: "s5-andra.wav", volume: 7, delay: 16)
            }
        }
        
        addFallingCupSound()
        addSpoonSound()
        
        if let chandelierNode = rootNode.childNode(withName: "chandelier", recursively: false) {
            attachAudio(to: chandelierNode, audioFileName: "rustyChandelier.mp3", volume: 0.9, delay: 9)
        }
        
        doorOpenNode.isHidden = true

        jumpscareDoll()

        dollNode.isHidden = true
        self.physicsWorld.contactDelegate = self
        
        // Apply font to necklaceLabel safely
        applyCustomFont(to: puzzleLabel, fontSize: 14)
    }
        
    func jumpscareDoll() {
        let playerPosition = (playerEntity.playerNode?.position)!

        DispatchQueue.main.asyncAfter(deadline: .now() + 22.0) { [weak self] in
            self?.isDollJumpscare = true
            self?.dollNode.isHidden = false
            
            self?.cameraNode.look(at: self!.dollNode.position)
            
            self?.attachAudio(to: self!.dollNode!, audioFileName: "jumpscare3.wav", volume: 40.0, delay: 0)

            self?.attachAudio(to: self!.dollNode!, audioFileName: "doll1.wav", volume: 4.5, delay: 1.0)
                        
            GameViewController.playerEntity?.movementComponent.movePlayer(to: SCNVector3(-65.851, -200.316, -80), duration: 0.2) {
                self?.cameraNode.look(at: self!.dollNode.position)

                // Animate zooming in by adjusting the camera's field of view
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.2
                self?.cameraNode.camera?.fieldOfView = 25  // Adjust this value for closer zoom
                SCNTransaction.commit()
                
                self?.cameraNode.look(at: self!.dollNode.position)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 32.0) { [weak self] in
            self?.cameraNode.camera?.fieldOfView = 75  // Default value for normal view

            guard let cameraNode = self?.cameraNode else { return }
            
            // Get current Euler angles and only adjust X and Z axes
            let eulerAngles = cameraNode.eulerAngles
            cameraNode.eulerAngles = SCNVector3(
                (self?.roundedAngle(eulerAngles.x * 180 / .pi) ?? 0) * .pi / 180, // Round X-axis
                eulerAngles.y, // Keep Y-axis unchanged
                (self?.roundedAngle(eulerAngles.z * 180 / .pi) ?? 0) * .pi / 180  // Round Z-axis
            )
            
            GameViewController.playerEntity?.movementComponent.movePlayer(to: playerPosition, duration: 1.5) {
                self?.isDollJumpscare = false
                self?.isJumpscareDone = true
            }
        }
    }
    
    func roundedAngle(_ angle: Float) -> Float {
        // Define the set of target angles
        let targets: [Float] = [-180, -90, 0, 90, 180]
        
        // Find the closest target angle
        return targets.min(by: { abs($0 - angle) < abs($1 - angle) }) ?? angle
    }
    
    func attachAudio(to node: SCNNode, audioFileName: String, volume: Float, delay: TimeInterval) {
        guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
            print("Warning: Audio file '\(audioFileName)' not found")
            return
        }
        
        if audioFileName == "s5-grandma.wav" || audioFileName == "s5-andra.wav" {
            audioSource.isPositional = false
        } else {
            audioSource.isPositional = true
        }
        
        if audioFileName == "muffledRain.wav" {
            audioSource.loops = true
        }
        
        audioSource.shouldStream = false
        audioSource.load()
        audioSource.volume = volume

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

    func displayPuzzlePieces(on view: UIView) {
        grandmaNode.isHidden = true
        let pieceImages = [
            "puzzle_piece_1.png", "puzzle_piece_2.png", "puzzle_piece_3.png",
            "puzzle_piece_4.png", "puzzle_piece_5.png", "puzzle_piece_6.png",
            "puzzle_piece_7.png", "puzzle_piece_8.png", "puzzle_piece_9.png",
            "puzzle_piece_10.png", "puzzle_piece_11.png", "puzzle_piece_12.png",
            "puzzle_piece_13.png", "puzzle_piece_14.png", "puzzle_piece_15.png",
            "puzzle_piece_16.png", "puzzle_piece_17.png"
        ]
        
        // Puzzle background setup
        puzzleBackground = UIView()
        puzzleBackground?.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let backgroundSize = CGSize(width: view.bounds.width * 0.6, height: view.bounds.height * 0.7)
        
        puzzleBackground?.frame = CGRect(
            x: (view.bounds.width - backgroundSize.width) / 2,
            y: (view.bounds.height - backgroundSize.height) / 2,
            width: backgroundSize.width,
            height: backgroundSize.height
        )
        puzzleBackground?.layer.cornerRadius = 20
        puzzleBackground?.layer.borderWidth = 0
        puzzleBackground?.clipsToBounds = true
        view.addSubview(puzzleBackground!)
        
        // Add puzzle pieces to the background
        for pieceImage in pieceImages {
            guard let image = UIImage(named: pieceImage) else { continue }
            
            let pieceSize = CGSize(width: image.size.width * 0.05, height: image.size.height * 0.05)
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(
                x: CGFloat(arc4random_uniform(UInt32(max(0, backgroundSize.width - pieceSize.width)))),
                y: CGFloat(arc4random_uniform(UInt32(max(0, backgroundSize.height - pieceSize.height)))),
                width: pieceSize.width,
                height: pieceSize.height
            )
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.accessibilityIdentifier = pieceImage
            
            // Add shadow to the puzzle piece
            imageView.layer.shadowColor = UIColor.black.cgColor
            imageView.layer.shadowOpacity = 0.5
            imageView.layer.shadowOffset = CGSize(width: 3, height: 3)
            imageView.layer.shadowRadius = 4
            imageView.layer.masksToBounds = false
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            imageView.addGestureRecognizer(panGesture)
            
            puzzleBackground?.addSubview(imageView)
        }
        
        isPlayingPuzzle = true
        
        // Restart the timer
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
        // Place the time label to the right of pipeBackground
        timeLabel = UILabel(frame: CGRect(
            x: puzzleBackground!.frame.maxX + 10,  // Position to the right of pipeBackground with a small padding
            y: puzzleBackground!.frame.minY / 2,       // Align vertically with the top of pipeBackground
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
        for i in 1...6 {
            let puzzleNodeName = "Puzzle_\(i)"
            if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                // Set the category bitmask for post-processing
                puzzleNode.isHidden = true
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
            // Call the function to handle game failure if time runs out
            triggerPuzzleFailedTransition()
        } else if isPhotoObtained {
            // Call the function to handle successful completion
            triggerPuzzleCompletionTransition()
        }
        
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
            triggerPuzzleFailedTransition()
        }
    }

    func triggerPuzzleFailedTransition() {
        print("Puzzle failed!")
        
        puzzleBackground?.removeFromSuperview()
        timeLabel.removeFromSuperview()
        // Invalidate the existing timer if it's running
        timer?.invalidate()
        
        // Reset the time limit to the starting value
        timeLimit = 210 // Set this to the initial time limit you want
        
        // Loop through each puzzle piece
        for i in 1...6 {
            let puzzleNodeName = "Puzzle_\(i)"
            if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                // Set the category bitmask for post-processing
                puzzleNode.isHidden = false
            }
        }

        isPhotoObtained = false
        isPlayingPuzzle = false
        isPuzzleFailed = true
        hasGroupedTwoPieces = false  // Track if two pieces have been grouped
        currentCombination = [] // Initialize currentCombination if not already done
    }

    func displayPhotoObtainedLabel(on view: UIView) {
        puzzleLabel.text = isPhotoObtained ? "Kirana's photo is obtained" : "You failed! Try again."
        view.addSubview(puzzleLabel)
        
        // Position the camera instruction label above the center of the screen
        let offsetFromTop: CGFloat = 170
        puzzleLabel.frame = CGRect(
            x: (view.bounds.width - 250) / 2,
            y: (view.bounds.height) / 2 - offsetFromTop,
            width: 255,
            height: 25
        )
        // Fade in the label
        UIView.animate(withDuration: 0.5) {
            self.puzzleLabel.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 0.5) {
                self.puzzleLabel.alpha = 0.0
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
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let piece = sender.view else { return }
        
        // Play the puzzle touch sound when the gesture begins
        if sender.state == .began {
            playPuzzleTouchSound()
        }
        
        let translation = sender.translation(in: piece.superview)
        
        let group = combinedPieces[piece] ?? [piece]
        
        // Get the bounds of the puzzle background
        guard let puzzleBackground = puzzleBackground else { return }
        let puzzleBounds = puzzleBackground.bounds
        
        // Calculate the group's bounding box
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = CGFloat.leastNormalMagnitude
        var maxY = CGFloat.leastNormalMagnitude
        
        for pieceInGroup in group {
            let pieceFrame = pieceInGroup.frame
            minX = min(minX, pieceFrame.minX)
            minY = min(minY, pieceFrame.minY)
            maxX = max(maxX, pieceFrame.maxX)
            maxY = max(maxY, pieceFrame.maxY)
        }
        
        // Calculate the translation for the group as a whole
        var groupTranslation = translation
        
        // Adjust translation to prevent the group from going outside the puzzle background bounds
        if minX + translation.x < puzzleBounds.minX {
            groupTranslation.x = puzzleBounds.minX - minX
        } else if maxX + translation.x > puzzleBounds.maxX {
            groupTranslation.x = puzzleBounds.maxX - maxX
        }
        
        if minY + translation.y < puzzleBounds.minY {
            groupTranslation.y = puzzleBounds.minY - minY
        } else if maxY + translation.y > puzzleBounds.maxY {
            groupTranslation.y = puzzleBounds.maxY - maxY
        }
        
        // Move all pieces in the group together
        for pieceInGroup in group {
            pieceInGroup.center = CGPoint(
                x: pieceInGroup.center.x + groupTranslation.x,
                y: pieceInGroup.center.y + groupTranslation.y
            )
        }
        
        // Reset translation to avoid compound translation
        sender.setTranslation(.zero, in: piece.superview)
        
        if sender.state == .ended {
            print("\(piece.accessibilityIdentifier ?? "Piece") dropped at position: \(piece.center)")
            
            // Check for nearby pieces to merge
            checkForNearbyPieces(piece)
        }
    }
    
    func playPuzzleTouchSound() {
        // Generate a random number between 1 and 10
        let randomIndex = Int.random(in: 1...10)
        // Create the file name based on the random number
        let fileName = "puzzle\(randomIndex).wav"
        
        // Attempt to load the randomly selected audio source
        guard let audioSource = SCNAudioSource(fileNamed: fileName) else {
            print("Warning: \(fileName) sound not found")
            return
        }
        
        audioSource.load()
        audioSource.volume = 3.0 // Set the volume as needed
        audioSource.isPositional = false // Set to false for background sound
        audioSource.shouldStream = false // Stream if it's a long sound
        
        // Create a node to attach the sound to
        let soundNode = SCNNode()
        soundNode.runAction(SCNAction.playAudio(audioSource, waitForCompletion: true))
        
        // Add the sound node to the root node
        rootNode.addChildNode(soundNode)
    }

    func checkForNearbyPieces(_ currentPiece: UIView) {
        guard let currentImageView = currentPiece as? UIImageView,
              let currentImageName = currentImageView.accessibilityIdentifier else { return }
        
        let currentGroup = combinedPieces[currentPiece] ?? [currentPiece]
        
        // Check if a current combination already exists
        if !currentCombination.isEmpty {
            if currentCombination.count < 17 {
                print("Current combination is in progress. Trying to add a new piece.")
            } else {
                print("Cannot create a new combination until the current one is completed.")
                return
            }
        }
        
        // Iterate through all the pieces in the current group
        for pieceInCurrentGroup in currentGroup {
            if let pieceInCurrentGroupImageView = pieceInCurrentGroup as? UIImageView,
               let currentGroupImageName = pieceInCurrentGroupImageView.accessibilityIdentifier,
               let currentNeighbors = neighbors[currentGroupImageName] {
                
                // Check for nearby neighbors for each piece in the current group
                for (neighborName, offset) in currentNeighbors {
                    if let neighborPiece = findPiece(byName: neighborName, in: currentPiece.superview) {
                        let neighborGroup = combinedPieces[neighborPiece] ?? [neighborPiece]
                        
                        // Calculate the actual distance between the piece in the current group and the neighbor piece
                        let distance = hypot(neighborPiece.center.x - pieceInCurrentGroup.center.x, neighborPiece.center.y - pieceInCurrentGroup.center.y)
                        
                        // Only snap the pieces together if they are within the snapDistance
                        if distance <= snapDistance {
                            // If the neighbor belongs to a different group, find the correct pieces to align them
                            if currentGroup != neighborGroup {
                                // Find the first piece in the current group that has a neighbor in the other group
                                if let (currentGroupPiece, neighborGroupPiece, alignmentOffset) = findMatchingNeighborPair(currentGroup: currentGroup, neighborGroup: neighborGroup) {
                                    
                                    // Calculate the alignment offset between the two groups
                                    let offsetX = currentGroupPiece.center.x + alignmentOffset.x - neighborGroupPiece.center.x
                                    let offsetY = currentGroupPiece.center.y + alignmentOffset.y - neighborGroupPiece.center.y
                                    
                                    // Apply the offset to align the entire neighbor group with the current group
                                    for piece in neighborGroup {
                                        piece.center = CGPoint(x: piece.center.x + offsetX, y: piece.center.y + offsetY)
                                    }
                                    
                                    // Merge the two groups into a single combined group
                                    let combinedGroup = Array(Set(currentGroup + neighborGroup))
                                    
                                    // Update the combinedPieces dictionary for all pieces in the combined group
                                    for piece in combinedGroup {
                                        combinedPieces[piece] = combinedGroup
                                    }
                                    
                                    // Update the current combination to reflect the new group
                                    currentCombination = combinedGroup
                                    
                                    // If all pieces are combined, mark the puzzle as completed
                                    if combinedGroup.count == 17 {
                                        completedCombinations.append(combinedGroup)
                                        checkForPuzzleCompletion()
                                    }
                                    
                                    print("Groups combined: \(currentImageName) and \(neighborName)")
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func findMatchingNeighborPair(currentGroup: [UIView], neighborGroup: [UIView]) -> (UIView, UIView, CGPoint)? {
        // Iterate through each piece in the current group
        for currentPiece in currentGroup {
            if let currentImageView = currentPiece as? UIImageView,
               let currentImageName = currentImageView.accessibilityIdentifier,
               let currentNeighbors = neighbors[currentImageName] {
                // Check if any piece in the neighbor group is listed as a neighbor
                for neighborPiece in neighborGroup {
                    if let neighborImageView = neighborPiece as? UIImageView,
                       let neighborImageName = neighborImageView.accessibilityIdentifier,
                       let alignmentOffset = currentNeighbors[neighborImageName] {
                        // We found a matching pair of neighbors, return them along with the alignment offset
                        return (currentPiece, neighborPiece, alignmentOffset)
                    }
                }
            }
        }
        // If no matching pair of neighbors was found, return nil
        return nil
    }
    
    func checkForPuzzleCompletion() {
        // Check if there are either 1 complete combination with 17 pieces or 2 combinations
        if completedCombinations.count == 1 && completedCombinations[0].count == 17 {
            print("Puzzle completed with one combination!")
            isPhotoObtained = true // Mark as completed
            timer?.invalidate() // Stop the timer
            timeLabel.removeFromSuperview()

            if timeLimit <= 0 {
                // Call the function to handle game failure if time runs out
                triggerPuzzleFailedTransition()
            } else if isPhotoObtained {
                // Call the function to handle successful completion
                triggerPuzzleCompletionTransition()
            }
            
            // Loop through each puzzle piece
            for i in 1...6 {
                let puzzleNodeName = "Puzzle_\(i)"
                if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                    // Set the category bitmask for post-processing
                    puzzleNode.isHidden = false
                }
            }
        }
    }
    
    func triggerPuzzleCompletionTransition() {
        puzzleBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        guard let superview = combinedPieces.keys.first?.superview else { return }
                
        // Get the center of the screen
        let screenCenter = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
        
        // Create an imageView for the completed puzzle image
        let fullPuzzleImageView = UIImageView(image: UIImage(named: "puzzle_full.png"))
        fullPuzzleImageView.frame.size = CGSize(width: 450, height: 350)
        fullPuzzleImageView.contentMode = .scaleAspectFit
        fullPuzzleImageView.alpha = 0  // Start with hidden image
        superview.addSubview(fullPuzzleImageView)
        
        // Animate each piece to the center of the screen
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            for (piece, _) in self.combinedPieces {
                piece.center = screenCenter  // Move each piece to the center
                piece.alpha = 0  // Fade out the pieces
            }
        }, completion: { _ in
            // Remove all individual pieces from the view after animation
            for (piece, _) in self.combinedPieces {
                piece.removeFromSuperview()
            }
            self.combinedPieces.removeAll()
            // Set initial properties for the fullPuzzleImageView
            fullPuzzleImageView.alpha = 0  // Start with the image hidden
            fullPuzzleImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)  // Start small
            
            // Center the image on the screen
            fullPuzzleImageView.center = screenCenter
            // Fade in the full puzzle image after the pieces are removed
            UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.2, options: [.curveEaseInOut], animations: {
                fullPuzzleImageView.alpha = 1
                fullPuzzleImageView.transform = CGAffineTransform.identity
            }, completion: { finished in
                // Automatically flip the puzzle image to the "Thank you" card after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.flipToCodeCard(imageView: fullPuzzleImageView)
                    self.addBlueFireAnimationNode()
                    self.isPhotoObtained = true
                }
            })
        })
    }
    
    func flipToCodeCard(imageView: UIImageView) {
        // Create a flip animation
        UIView.transition(with: imageView, duration: 1, options: [.transitionFlipFromLeft], animations: {
            // Change the image to the "Thankyou card" image
            //            imageView.image = UIImage(named: "backPuzzleCode.png")
            imageView.image = UIImage(named: "thankyou card.png")
            imageView.frame.size = CGSize(width: 450, height: 350)
            self.attachAudio(to: self.rootNode, audioFileName: "puzzleFinish.wav", volume: 3, delay: 0)
        }, completion: nil)
        
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
        //            self.puzzleBackground?.removeFromSuperview()
        //            self.isPlayingPuzzle = false
        //            self.isCodeDone = true
        //            self.doorCloseNode.isHidden = true
        //            self.doorOpenNode.isHidden = false
        //            self.attachAudio(to: self.doorOpenNode, audioFileName: "door_open.mp3", volume: 3, delay: 0)
        //        }
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
    }
    
    // Check if the player is close to the transition trigger point
     func checkProximityToTransition() -> Bool {
         guard let playerPosition = playerEntity.playerNode?.position else { return false }
         let distance = playerPosition.distance(to: transitionTriggerPosition)
         return distance < triggerDistance
     }

    func findPiece(byName name: String, in superview: UIView?) -> UIView? {
        guard let superview = superview else { return nil }
        
        for subview in superview.subviews {
            if let imageView = subview as? UIImageView, let imageName = imageView.accessibilityIdentifier {
                if imageName == name {
                    return imageView
                }
            }
        }
        return nil
    }
    
    // Proximity check to Obj_Cake_003
    func checkProximityToCake(interactButton: UIButton) {
        guard let playerNode = playerEntity.playerNode, let objCakeNode = objCakeNode else {
            print("Error: Player node or Cake node not found")
            return
        }
        
        // Calculate the distance between the player and the cake
        let distance = playerNode.position.distance(to: objCakeNode.position)
        
        // If the player is within proximity, show the button and enable the glow
        if isPlayingPuzzle == true || isPhotoObtained == true || distance > proximityDistance {
            interactButton.isHidden = true // Hide the button
            toggleGlowEffect(isEnabled: false)
        } else if isJumpscareDone && (distance < proximityDistance && isPhotoObtained == false && isCodeDone == false) {
            interactButton.setTitle("Arrange photo", for: .normal)
            interactButton.isHidden = false // Show the button
            toggleGlowEffect(isEnabled: true)
        }
    }
    
    func toggleGlowEffect(isEnabled: Bool) {
        if isEnabled {
            objCakeNode.categoryBitMask = 2
            
            // Loop through each puzzle piece and set the category bitmask
            for i in 2...6 {
                let puzzleNodeName = "Puzzle_\(i)"
                if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                    puzzleNode.categoryBitMask = 2
                }
            }
        } else {
            // Disable the technique
            scnView?.technique = nil
            objCakeNode.categoryBitMask = 1

            // Reset the category bitmask if needed
            for i in 2...6 {
                let puzzleNodeName = "Puzzle_\(i)"
                if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                    puzzleNode.categoryBitMask = 1
                }
            }
        }
    }
    
    func addFallingCupSound() {
        // Find the cup node
        guard let cupNode = rootNode.childNode(withName: "cup", recursively: true) else {
            print("Warning: Cup node not found")
            return
        }
        
        // Load the sound effect
        let audioSource = SCNAudioSource(fileNamed: "fallingCup.mp3")!
        audioSource.load()
        audioSource.volume = 30.0 // Set the volume as needed
        
        // Create an action to play the sound after 3 seconds
        let wait = SCNAction.wait(duration: 20.0)
        let playSound = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the actions sequentially
        cupNode.runAction(SCNAction.sequence([wait, playSound]))
    }
    
    func addOpenFridgeSound() {
        // Find the cup node
        guard let fridgeNode = rootNode.childNode(withName: "fridge", recursively: true) else {
            print("Warning: Cup node not found")
            return
        }
        
        // Load the sound effect
        let audioSource = SCNAudioSource(fileNamed: "openFridge.mp3")!
        audioSource.load()
        audioSource.volume = 20.0 // Set the volume as needed
        
        let playSound = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the actions sequentially
        fridgeNode.runAction(SCNAction.sequence([playSound]))
    }
    
    func addCloseFridgeSound() {
        // Find the cup node
        guard let fridgeNode = rootNode.childNode(withName: "fridge", recursively: true) else {
            print("Warning: Cup node not found")
            return
        }
        
        // Load the sound effect
        let audioSource = SCNAudioSource(fileNamed: "closeFridge.mp3")!
        audioSource.load()
        audioSource.volume = 25.0 // Set the volume as needed
        
        let playSound = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the actions sequentially
        fridgeNode.runAction(SCNAction.sequence([playSound]))
    }
    
    func addSpoonSound() {
        // Find the cup node
        guard let spoonNode = rootNode.childNode(withName: "fork", recursively: true) else {
            print("Warning: Cup node not found")
            return
        }
        
        // Load the sound effect
        let audioSource = SCNAudioSource(fileNamed: "movingSpoon.mp3")!
        audioSource.load()
        audioSource.volume = 1.0 // Set the volume as needed
        
        // Create an action to play the sound after 3 seconds
        let wait = SCNAction.wait(duration: 25.0)
        let playSound = SCNAction.playAudio(audioSource, waitForCompletion: false)
        
        // Run the actions sequentially
        spoonNode.runAction(SCNAction.sequence([wait, playSound]))
    }
    
    func addBackgroundSound(audioFileName: String, volume: Float = 0.9, delay: TimeInterval = 0) {
        // Load the sound effect and attach to node
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            guard let audioSource = SCNAudioSource(fileNamed: audioFileName) else {
                print("Warning: Audio file '\(audioFileName)' not found")
                return
            }
            
            // Configure audio properties
            audioSource.isPositional = true
            audioSource.shouldStream = false
            audioSource.volume = volume
            audioSource.load()
            audioSource.loops = true
            
            // Prepare action sequence with delay and playback
            let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
            let waitAction = SCNAction.wait(duration: delay)
            let sequenceAction = SCNAction.sequence([waitAction, playAudioAction])
            
            // Run the action on the node
            muffledNode.runAction(sequenceAction)
        } else {
            print("Warning: Node 'muffledRain' not found in the scene.")
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

// SCNVector3 extension to calculate the distance between two points
extension SCNVector3 {
    func distance(to vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
}
