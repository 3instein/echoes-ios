import SceneKit
import UIKit

class Scene6: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var combinedPieces: [UIView: [UIView]] = [:]  // Dictionary that tracks combined pieces
    var completedCombinations: [[UIView]] = []  // Track completed combinations
    
    var objCakeNode: SCNNode!  // Add a reference for Obj_Cake_003
    let proximityDistance: Float = 180.0  // Define a proximity distance
    
    weak var scnView: SCNView?
    var puzzleBackground: UIView?
    var playButton: UIButton?  // Store a reference to the play button
    
    var isPuzzleDisplayed: Bool = false
    var isGameCompleted: Bool = false  // Track if the game is completed
    let snapDistance: CGFloat = 50.0
    
    var timer: Timer?
    var timeLimit: Int = 210 // 5-minute timer
    var timeLabel: UILabel?
    
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
    
    init(lightNode: SCNNode) {
        super.init()
        self.lightNode = lightNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene6.scn") else {
            print("Warning: House scene 'Scene 6.scn' not found")
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
        objCakeNode = rootNode.childNode(withName: "Puzzle_3", recursively: true)
        
        addFallingCupSound()
        addSpoonSound()
        addBackgroundSound(audioFileName: "muffledRain.wav")  // Add this line to play background sound
        
        self.physicsWorld.contactDelegate = self
    }
    
    func displayPuzzlePieces(on view: UIView) {
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
        puzzleBackground?.backgroundColor = UIColor.white.withAlphaComponent(0.8)
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
        
        // Add time label to the top of the white box
        timeLabel = UILabel(frame: CGRect(
            x: puzzleBackground!.frame.minX,
            y: puzzleBackground!.frame.minY - 50, // Position slightly above the white box
            width: backgroundSize.width, height: 50))
        timeLabel?.textAlignment = .center
        timeLabel?.font = UIFont.boldSystemFont(ofSize: 24) // Bigger font size
        timeLabel?.textColor = .white
        updateTimeLabel() // Set the initial time
        view.addSubview(timeLabel!)
        
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
        
        isPuzzleDisplayed = true
        
        // Dismiss puzzle when clicking outside the white rectangle
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPuzzle(_:)))
        view.addGestureRecognizer(tapGesture)
        
        // Start the timer
        startTimer()
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
        triggerPuzzleFailedTransition() // Implement your failure transition logic here
        
        // Create a temporary UITapGestureRecognizer
        let tapGesture = UITapGestureRecognizer()
        dismissPuzzle(tapGesture) // Dismiss the puzzle using the temporary gesture recognizer
    }
    
    // Show failure transition logic
    func triggerPuzzleFailedTransition() {
        isGameCompleted = true
        puzzleBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        guard let superview = puzzleBackground?.superview else { return }
        
        // Get the center of the screen
        let screenCenter = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)
        
        timeLabel?.isHidden = true
        
        // Create an imageView for the completed puzzle image
        let fullPuzzleImageView = UIImageView(image: UIImage(named: "failed card.png"))
        fullPuzzleImageView.frame.size = CGSize(width: 450, height: 350)
        fullPuzzleImageView.contentMode = .scaleAspectFit
        fullPuzzleImageView.alpha = 0  // Start with hidden image
        superview.addSubview(fullPuzzleImageView)
        
        // Animate each piece to the center of the screen
        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
            for piece in self.puzzleBackground?.subviews ?? [] {
                if let imageView = piece as? UIImageView {
                    imageView.center = screenCenter  // Move each piece to the center
                    imageView.alpha = 0  // Fade out the pieces
                }
            }
        }, completion: { _ in
            // Remove all individual pieces from the view after animation
            for piece in self.puzzleBackground?.subviews ?? [] {
                if let imageView = piece as? UIImageView {
                    imageView.removeFromSuperview()
                }
            }
            
            // Set initial properties for the fullPuzzleImageView
            fullPuzzleImageView.alpha = 0  // Start with the image hidden
            fullPuzzleImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)  // Start small
            
            // Center the image on the screen
            fullPuzzleImageView.center = screenCenter
            
            // Fade in the full puzzle image after the pieces are removed
            UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                fullPuzzleImageView.alpha = 1
                fullPuzzleImageView.transform = CGAffineTransform.identity
            })
        })
    }
    
    @objc func dismissPuzzle(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: puzzleBackground?.superview)
        if let puzzleFrame = puzzleBackground?.frame, !puzzleFrame.contains(tapLocation) {
            // Check if the game is completed before dismissing
            if !isGameCompleted {
                puzzleBackground?.removeFromSuperview()
                timeLabel?.removeFromSuperview()
                isPuzzleDisplayed = false
                timer?.invalidate()
                addCloseFridgeSound()
            }
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
        guard let audioSource = SCNAudioSource(fileNamed: "puzzle.mp3") else {
            print("Warning: puzzle.mp3 sound not found")
            return
        }
        
        audioSource.load()
        audioSource.volume = 5.0 // Set the volume as needed
        audioSource.isPositional = false  // Set to false for background sound
        audioSource.shouldStream = false     // Stream if it's a long sound
        
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
            isGameCompleted = true // Mark as completed
            timer?.invalidate() // Stop the timer
            checkGameEnd() // Check the game end conditions
        } else if completedCombinations.count == 2 {
            print("Puzzle completed with two combinations!")
            isGameCompleted = true // Mark as completed
            timer?.invalidate() // Stop the timer
            checkGameEnd(); // Check the game end conditions
        }
    }
    
    func checkGameEnd() {
        if timeLimit <= 0 {
            // Call the function to handle game failure if time runs out
            timeOut()
            triggerPuzzleFailedTransition()
        } else if isGameCompleted {
            // Call the function to handle successful completion
            triggerPuzzleCompletionTransition()
        }
    }
    
    func triggerPuzzleCompletionTransition() {
        isGameCompleted = true
        puzzleBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)
        
        guard let superview = combinedPieces.keys.first?.superview else { return }
        
        timeLabel?.removeFromSuperview()
        
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.flipToThankYouCard(imageView: fullPuzzleImageView)
                }
            })
        })
    }
    
    func flipToThankYouCard(imageView: UIImageView) {
        // Create a flip animation
        UIView.transition(with: imageView, duration: 1, options: [.transitionFlipFromLeft], animations: {
            // Change the image to the "Thankyou card" image
            imageView.image = UIImage(named: "thankyou card.png")
            imageView.frame.size = CGSize(width: 450, height: 350)
            
        }, completion: nil)
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
        if isPuzzleDisplayed == true || distance > proximityDistance {
            interactButton.isHidden = true // Hide the button
            toggleGlowEffect(isEnabled: false)
        } else {
            interactButton.isHidden = false // Show the button
            isPuzzleDisplayed = false
            toggleGlowEffect(isEnabled: true)
        }
    }
    
    func toggleGlowEffect(isEnabled: Bool) {
        if isEnabled {
            // Load and apply the SCNTechnique for the glow effect
            if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist"),
               let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                let technique = SCNTechnique(dictionary: dict)
                let glowColor = SCNVector3(0.8, 1.0, 0.2)
                technique?.setValue(NSValue(scnVector3: glowColor), forKeyPath: "glowColorSymbol")
                scnView?.technique = technique
            }
            
            // Loop through each puzzle piece and set the category bitmask
            for i in 1...6 {
                let puzzleNodeName = "Puzzle_\(i)"
                if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                    puzzleNode.categoryBitMask = 2
                }
            }
        } else {
            // Disable the technique
            scnView?.technique = nil
            
            // Reset the category bitmask if needed
            for i in 1...6 {
                let puzzleNodeName = "Puzzle_\(i)"
                if let puzzleNode = rootNode.childNode(withName: puzzleNodeName, recursively: true) {
                    puzzleNode.categoryBitMask = 0
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
        let wait = SCNAction.wait(duration: 3.0)
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
        let wait = SCNAction.wait(duration: 18.0)
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
