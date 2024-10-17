import SceneKit
import UIKit

class Scene1: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!
    var combinedPieces: [UIView: [UIView]] = [:]  // Dictionary that tracks combined pieces
    var completedCombinations: [[UIView]] = []  // Track completed combinations

    weak var scnView: SCNView?

    override init() {
        super.init()

        lightNode = SCNNode()

        guard let houseScene = SCNScene(named: "scene1.scn") else {
            print("Warning: House scene 'Scene 1.scn' not found")
            return
        }

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

        cameraNode.camera?.fieldOfView = 75
        cameraNode.camera?.automaticallyAdjustsZRange = true
        cameraComponent = CameraComponent(cameraNode: cameraNode)

        let light = SCNLight()
        light.type = .omni
        light.intensity = 20
        lightNode.light = light

        lightNode.position = playerNode.position
        rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 20
        ambientLight.color = UIColor.blue
        ambientLightNode.light = ambientLight
        rootNode.addChildNode(ambientLightNode)

        let movementComponent = MovementComponent(playerNode: playerNode, cameraNode: cameraNode, lightNode: lightNode)
        playerEntity.addComponent(movementComponent)
    }

    func updateLightPosition() {
        guard let playerNode = playerEntity.playerNode else { return }
        lightNode.position = playerNode.position
    }

    //         let pieceImages = ["puzzle_piece_1.png", "puzzle_piece_2.png", "puzzle_piece_3.png", "puzzle_piece_4.png", "puzzle_piece_5.png", "puzzle_piece_6.png", "puzzle_piece_7.png", "puzzle_piece_8.png", "puzzle_piece_9.png", "puzzle_piece_10.png", "puzzle_piece_11.png", "puzzle_piece_12.png", "puzzle_piece_13.png", "puzzle_piece_14.png","puzzle_piece_15.png", "puzzle_piece_16.png", "puzzle_piece_17.png"]

    func displayPuzzlePieces(on view: UIView) {
        let pieceImages = [
            "puzzle_piece_1.png", "puzzle_piece_2.png", "puzzle_piece_3.png",
            "puzzle_piece_4.png", "puzzle_piece_5.png", "puzzle_piece_6.png",
            "puzzle_piece_7.png", "puzzle_piece_8.png", "puzzle_piece_9.png",
            "puzzle_piece_10.png", "puzzle_piece_11.png", "puzzle_piece_12.png",
            "puzzle_piece_13.png", "puzzle_piece_14.png", "puzzle_piece_15.png",
            "puzzle_piece_16.png", "puzzle_piece_17.png"
        ]

        let puzzleBackground = UIView()
        puzzleBackground.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        let backgroundSize = CGSize(width: view.bounds.width * 0.6, height: view.bounds.height * 0.7)
        puzzleBackground.frame = CGRect(
            x: (view.bounds.width - backgroundSize.width) / 2,
            y: (view.bounds.height - backgroundSize.height) / 2,
            width: backgroundSize.width,
            height: backgroundSize.height
        )
        puzzleBackground.layer.cornerRadius = 20
        puzzleBackground.layer.borderWidth = 2
        puzzleBackground.layer.borderColor = UIColor.white.cgColor
        puzzleBackground.clipsToBounds = true

        view.addSubview(puzzleBackground)

        for pieceImage in pieceImages {
            guard let image = UIImage(named: pieceImage) else { continue }

            var pieceSize: CGSize

            // Scale width and height by 0.4 for all pieces except 4, 5, and 15
            pieceSize = CGSize(width: image.size.width * 0.05, height: image.size.height * 0.05)

            // Ensure pieceSize does not exceed backgroundSize
            pieceSize.width = min(pieceSize.width, backgroundSize.width)
            pieceSize.height = min(pieceSize.height, backgroundSize.height)

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

            puzzleBackground.addSubview(imageView)
        }
    }

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

    let snapDistance: CGFloat = 50.0

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
            endLabel.text = "The End"
            endLabel.textColor = .white
            // Load and apply the custom font for buttons
            if let customFont = UIFont(name: "SpecialElite-Regular", size: 32) {
                endLabel.font = customFont
            } else {
                print("Failed to load SpecialElite-Regular font.")
            }
            endLabel.textAlignment = .center
            endLabel.backgroundColor = UIColor.black.withAlphaComponent(1) // Optional background
            endLabel.layer.cornerRadius = 10
            endLabel.clipsToBounds = true
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

    func setupGestureRecognizers(for view: UIView) {
            cameraComponent.setupGestureRecognizers(for: view)
        }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}



