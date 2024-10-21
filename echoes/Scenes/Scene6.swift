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
    let proximityDistance: Float = 150.0  // Define a proximity distance
    
    weak var scnView: SCNView?
    var puzzleBackground: UIView?
    var playButton: UIButton?  // Store a reference to the play button
    
    var isPuzzleDisplayed: Bool = false
    var isGameCompleted: Bool = false  // Track if the game is completed
    let snapDistance: CGFloat = 50.0

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
        
//        // Add a default light to the scene
//        let light = SCNLight()
//        light.type = .omni
//        light.intensity = 500
//        light.color = UIColor.white
//        lightNode.light = light
//        
//        // Set the initial position of the lightNode to match the playerNode's position
//        lightNode.position = playerNode.position
//        rootNode.addChildNode(lightNode)
//        
//        // Add an ambient light to the scene
//        let ambientLightNode = SCNNode()
//        let ambientLight = SCNLight()
//        ambientLight.type = .ambient
//        ambientLight.intensity = 500
//        ambientLight.color = UIColor.blue
//        ambientLightNode.light = ambientLight
//        rootNode.addChildNode(ambientLightNode)
        
        rootNode.addChildNode(lightNode)
        
        // Initialize MovementComponent with lightNode reference
        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
        
        // Find Obj_Cake_003 node in the scene
        objCakeNode = rootNode.childNode(withName: "Puzzle_Object", recursively: true)
        
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
    }
    
    @objc func dismissPuzzle(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: puzzleBackground?.superview)
        if let puzzleFrame = puzzleBackground?.frame, !puzzleFrame.contains(tapLocation) {
            // Check if the game is completed before dismissing
            if !isGameCompleted {
                puzzleBackground?.removeFromSuperview()
                isPuzzleDisplayed = false
            }
        }
    }

    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let piece = sender.view else { return }
        let translation = sender.translation(in: piece.superview)

        let group = combinedPieces[piece] ?? [piece]

        // Move all pieces in the group together
        for pieceInGroup in group {
            pieceInGroup.center = CGPoint(x: pieceInGroup.center.x + translation.x, y: pieceInGroup.center.y + translation.y)
        }

        sender.setTranslation(.zero, in: piece.superview)

        if sender.state == .ended {
            print("\(piece.accessibilityIdentifier ?? "Piece") dropped at position: \(piece.center)")

            // Check for nearby pieces
            checkForNearbyPieces(piece)
        }
    }

    func checkForNearbyPieces(_ currentPiece: UIView) {
        guard let currentImageView = currentPiece as? UIImageView,
              let currentImageName = currentImageView.accessibilityIdentifier else { return }

        let currentGroup = combinedPieces[currentPiece] ?? [currentPiece]

        if let currentNeighbors = neighbors[currentImageName] {
            for (neighborName, offset) in currentNeighbors {
                if let neighborPiece = findPiece(byName: neighborName, in: currentPiece.superview) {
                    let neighborGroup = combinedPieces[neighborPiece] ?? [neighborPiece]

                    if let pieceInCurrentGroup = currentGroup.first {
                        let expectedPosition = CGPoint(
                            x: pieceInCurrentGroup.center.x + offset.x,
                            y: pieceInCurrentGroup.center.y + offset.y
                        )

                        let distance = hypot(neighborPiece.center.x - expectedPosition.x,
                                             neighborPiece.center.y - expectedPosition.y)

                        if distance <= snapDistance {
                            let offsetX = expectedPosition.x - neighborPiece.center.x
                            let offsetY = expectedPosition.y - neighborPiece.center.y

                            for piece in neighborGroup {
                                piece.center = CGPoint(x: piece.center.x + offsetX, y: piece.center.y + offsetY)
                            }

                            let combinedGroup = Array(Set(currentGroup + neighborGroup))

                            for piece in combinedGroup {
                                combinedPieces[piece] = combinedGroup
                            }

                            if combinedGroup.count == 17 {
                                // Add completed group to the completed combinations
                                completedCombinations.append(combinedGroup)
                                checkForPuzzleCompletion()
                            }

                            print("Pieces combined: \(currentImageName) and \(neighborName)")
                            return
                        }
                    }
                }
            }
        }
    }

    func checkForPuzzleCompletion() {
        // Check if there are either 1 complete combination with 17 pieces or 2 combinations
        if completedCombinations.count == 1 && completedCombinations[0].count == 17 {
            print("Puzzle completed with one combination!")
            triggerPuzzleCompletionTransition()
        } else if completedCombinations.count == 2 {
            print("Puzzle completed with two combinations!")
            triggerPuzzleCompletionTransition()
        }
    }

    func triggerPuzzleCompletionTransition() {
        isGameCompleted = true
        puzzleBackground?.backgroundColor = UIColor.white.withAlphaComponent(0)

        guard let superview = combinedPieces.keys.first?.superview else { return }

        // Get the center of the screen
        let screenCenter = CGPoint(x: superview.bounds.midX, y: superview.bounds.midY)

        // Create an imageView for the completed puzzle image
        let fullPuzzleImageView = UIImageView(image: UIImage(named: "puzzle_full.png"))
        fullPuzzleImageView.frame.size = CGSize(width: 300, height: 200)
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
            fullPuzzleImageView.center = screenCenter  // Ensure it is centered
            UIView.animate(withDuration: 2.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: [.curveEaseInOut], animations: {
                fullPuzzleImageView.alpha = 1
                fullPuzzleImageView.transform = CGAffineTransform.identity
            }, completion: { finished in
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleFullPuzzleTap(_:)))
                fullPuzzleImageView.isUserInteractionEnabled = true
                fullPuzzleImageView.addGestureRecognizer(tapGesture)
            })

        })
    }
    
    @objc func handleFullPuzzleTap(_ sender: UITapGestureRecognizer) {
        guard let imageView = sender.view as? UIImageView else { return }

        // Create a flip animation
        UIView.transition(with: imageView, duration: 1, options: [.transitionFlipFromLeft], animations: {
            // Change the image to a blank image or add a label with "The End"
            imageView.image = nil  // Optionally set to a blank image
            let endLabel = UILabel(frame: imageView.bounds)
            endLabel.text = "Bravo! You’ve done it! \nBut the truth is just beginning to unfold. Stay tuned for the next part of the story."
            endLabel.textColor = .white
            // Load and apply the custom font for buttons
            if let customFont = UIFont(name: "SpecialElite-Regular", size: 18) {
                endLabel.font = customFont
            } else {
                print("Failed to load SpecialElite-Regular font.")
            }
            endLabel.textAlignment = .center
            endLabel.backgroundColor = UIColor.black.withAlphaComponent(1) // Optional background
            endLabel.layer.cornerRadius = 10
            endLabel.clipsToBounds = true
            endLabel.numberOfLines = 0  // Allows unlimited lines
            endLabel.preferredMaxLayoutWidth = 200
            endLabel.lineBreakMode = .byWordWrapping  // Wraps text by words
            imageView.addSubview(endLabel)  // Add the label to the imageView
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

        // If the player is within the proximity distance, show the button; otherwise, hide it
        if isPuzzleDisplayed == true || distance > proximityDistance {
            interactButton.isHidden = true // Hide the button
        } else {
            interactButton.isHidden = false // Show the button
            isPuzzleDisplayed = false
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
