import SceneKit
import UIKit

class Scene1: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!

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

    func displayPuzzlePieces(on view: UIView) {
        let maxSize = CGSize(width: 100, height: 100)
        let pieceImages = ["puzzle_piece_1.png", "puzzle_piece_2.png", "puzzle_piece_3.png", "puzzle_piece_4.png", "puzzle_piece_5.png", "puzzle_piece_6.png", "puzzle_piece_7.png", "puzzle_piece_8.png", "puzzle_piece_9.png", "puzzle_piece_10.png", "puzzle_piece_11.png", "puzzle_piece_12.png", "puzzle_piece_13.png", "puzzle_piece_14.png","puzzle_piece_15.png", "puzzle_piece_16.png", "puzzle_piece_17.png"]

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

            let aspectRatio = image.size.width / image.size.height
            var pieceSize: CGSize

            if aspectRatio > 1 {
                pieceSize = CGSize(width: maxSize.width, height: maxSize.width / aspectRatio)
            } else {
                pieceSize = CGSize(width: maxSize.height * aspectRatio, height: maxSize.height)
            }

            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(
                x: CGFloat(arc4random_uniform(UInt32(backgroundSize.width - pieceSize.width))),
                y: CGFloat(arc4random_uniform(UInt32(backgroundSize.height - pieceSize.height))),
                width: pieceSize.width,
                height: pieceSize.height
            )
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            imageView.accessibilityIdentifier = pieceImage

            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            imageView.addGestureRecognizer(panGesture)

            puzzleBackground.addSubview(imageView)
        }
    }

    let neighbors: [String: [String: CGPoint]] = [
        "puzzle_piece_1.png": ["puzzle_piece_2.png": CGPoint(x: 30, y: -20)],  // Right neighbor
        "puzzle_piece_2.png": ["puzzle_piece_1.png": CGPoint(x: -30, y: 20), "puzzle_piece_3.png": CGPoint(x: 30, y: -20)],
        "puzzle_piece_3.png": ["puzzle_piece_1.png": CGPoint(x: -50, y: 10), "puzzle_piece_2.png": CGPoint(x: -30, y: 20), "puzzle_piece_4.png": CGPoint(x: 30, y: -20), "puzzle_piece_9.png": CGPoint(x: -30, y: 50), "puzzle_piece_10.png": CGPoint(x: 20, y: 70)]
    ]

    let snapDistance: CGFloat = 20.0

    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let piece = sender.view else { return }
        let translation = sender.translation(in: piece.superview)

        piece.center = CGPoint(x: piece.center.x + translation.x, y: piece.center.y + translation.y)

        sender.setTranslation(.zero, in: piece.superview)

        if let puzzleBackground = piece.superview {
            let pieceFrame = piece.frame

            let minX = puzzleBackground.bounds.minX
            let maxX = puzzleBackground.bounds.maxX - pieceFrame.width
            let minY = puzzleBackground.bounds.minY
            let maxY = puzzleBackground.bounds.maxY - pieceFrame.height

            if pieceFrame.origin.x < minX {
                piece.frame.origin.x = minX
            }
            if pieceFrame.origin.x > maxX {
                piece.frame.origin.x = maxX
            }
            if pieceFrame.origin.y < minY {
                piece.frame.origin.y = minY
            }
            if pieceFrame.origin.y > maxY {
                piece.frame.origin.y = maxY
            }
        }

        if sender.state == .ended {
            print("\(piece.accessibilityIdentifier ?? "Piece") dropped at position: \(piece.center)")
        }

        checkForNearbyPieces(piece)
    }

    func checkForNearbyPieces(_ currentPiece: UIView) {
        guard let currentImageView = currentPiece as? UIImageView,
              let currentImageName = currentImageView.accessibilityIdentifier else { return }

        if let currentNeighbors = neighbors[currentImageName] {
            for (neighborName, offset) in currentNeighbors {
                if let neighborPiece = findPiece(byName: neighborName, in: currentPiece.superview) {
                    // Calculate the expected position for the neighbor based on the current piece's position and the offset
                    let expectedPosition = CGPoint(x: currentPiece.center.x + offset.x,
                                                    y: currentPiece.center.y + offset.y)

                    // Calculate distance between the neighbor's frame and expected position
                    let neighborFrame = neighborPiece.frame

                    // Calculate the distance to the center of the neighbor's frame
                    let distance = hypot(neighborFrame.midX - expectedPosition.x,
                                         neighborFrame.midY - expectedPosition.y)

                    print("Checking distance for \(currentImageName) and \(neighborName): \(distance) (snapDistance: \(snapDistance))")

                    // If the neighbor is within the snap distance, snap it to the expected position
                    if distance <= snapDistance {
                        // Snap the neighbor to the expected position
                        neighborPiece.center = expectedPosition

                        // Optionally disable interaction with the neighbor and current piece
                        neighborPiece.isUserInteractionEnabled = false
                        currentPiece.isUserInteractionEnabled = false

                        print("Pieces combined: \(currentImageName) and \(neighborName)")
                    }
                }
            }
        }
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



