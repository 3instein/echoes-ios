//  MovementComponent.swift

import GameplayKit
import SceneKit
import AVFoundation

class MovementComponent: GKComponent, SCNPhysicsContactDelegate {
    let playerNode: SCNNode
    let movementSpeed: Float = 60
    var joystickComponent: VirtualJoystickComponent?
    var cameraNode: SCNNode?
    var movingProgramatically: Bool = false

    private var lastSafePosition: SCNVector3?

    // Light node reference
    var lightNode: SCNNode?
    var originalLightIntensity: CGFloat = 75 // Default intensity
    var isLightActive = false // Track if light is active
    private var lightIncreaseDuration: TimeInterval = 0.5 // Reduced duration for increasing intensity
    private var lightDecreaseDuration: TimeInterval = 0.3 // Reduced duration for decreasing intensity
    private var lightTimer: Timer?
    private var lightTimerDelay: TimeInterval = 1.0 // Reduced delay before light starts dimming
    
    // Sound properties
    var echoAudioPlayer: AVAudioPlayer?
    private var lastStepTime: Date?
    private let stepDelay: TimeInterval = 2.0 // Minimum delay between steps

    var stepAudioPlayer: AVAudioPlayer?
    private let minStepDelay: TimeInterval = 0.2 // Minimum delay between steps
    private let maxStepDelay: TimeInterval = 1.0 // Maximum delay between steps
    private var isWalking = false // Track if the player is walking

    init(playerNode: SCNNode, cameraNode: SCNNode?, lightNode: SCNNode?) {
        print("movecomp init")
        self.playerNode = playerNode
        self.cameraNode = cameraNode
        self.lightNode = lightNode
        self.originalLightIntensity = lightNode?.light?.intensity ?? 75 // Set original intensity

        super.init()
        
        // Load sound
        loadSounds()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime seconds: TimeInterval) {
        if (!movingProgramatically) {
            guard let joystick = joystickComponent, joystick.isTouching, let cameraNode = cameraNode else {
                stepAudioPlayer?.stop()
                return
            }
            
            lastSafePosition = playerNode.position

            addPlayerPhysicsBody()

            let direction = joystick.direction
            let deltaTime = Float(seconds)

            let cameraTransform = cameraNode.transform

            var forwardVector = SCNVector3(cameraTransform.m31, 0, cameraTransform.m33)
            forwardVector = forwardVector.normalized()
            var rightVector = SCNVector3(cameraTransform.m11, 0, cameraTransform.m13)
            rightVector = rightVector.normalized()

            let forwardMovement = forwardVector * Float(direction.y) * movementSpeed * deltaTime
            let rightMovement = rightVector * Float(direction.x) * movementSpeed * deltaTime

            let movementVector = forwardMovement + rightMovement

            playerNode.localTranslate(by: movementVector)

            updateLightPosition()

            let speed = movementVector.length() / deltaTime

            if speed > 0 {
                playEchoSound()
                if !stepAudioPlayer!.isPlaying {
                    playStepSound()
                }
            } else {
                stopStepSound()
                isWalking = false
            }

            if !isLightActive {
                activateLightPulsing()
            }
        } else if (movingProgramatically) {
            updateLightPosition()

            let currentTime = Date()
            if lastStepTime == nil || currentTime.timeIntervalSince(lastStepTime!) >= stepDelay {
                playEchoSound()
                lastStepTime = currentTime
            }

            // User is moving
            if !isLightActive {
                activateLightPulsing()
            }
        }
    }

    private func updateLightPosition() {
        guard let lightNode = lightNode else { return }
        // Update the light position to follow the player
        lightNode.position = SCNVector3(playerNode.position.x, playerNode.position.y + 5, playerNode.position.z) // Adjust height as necessary
    }

    func activateLightPulsing() {
        guard let lightNode = lightNode else { return }

        isLightActive = true

        // Increase light intensity smoothly
        let targetIntensity: CGFloat = originalLightIntensity + 500 // Set the target intensity
        let increaseAction = SCNAction.customAction(duration: lightIncreaseDuration) { node, elapsedTime in
            let percent = elapsedTime / CGFloat(self.lightIncreaseDuration)
            let newIntensity = self.originalLightIntensity + (500 * percent) // Change 500 to desired increase amount
            node.light?.intensity = newIntensity
        }

        lightNode.runAction(increaseAction)

        // Schedule a timer to decrease intensity after a shorter delay
        lightTimer?.invalidate() // Invalidate any existing timer
        lightTimer = Timer.scheduledTimer(withTimeInterval: lightTimerDelay, repeats: false) { [weak self] _ in
            self?.decreaseLightIntensity()
        }
    }

    private func decreaseLightIntensity() {
        guard let lightNode = lightNode else { return }
        print("decreasing")

        // Decrease light intensity smoothly
        let decreaseAction = SCNAction.customAction(duration: lightDecreaseDuration) { node, elapsedTime in
            let percent = elapsedTime / CGFloat(self.lightDecreaseDuration)
            let newIntensity = self.originalLightIntensity + (500 * (1 - percent)) // Reverse the increase effect
            node.light?.intensity = newIntensity // Ensure it doesn't go below original
            
        }

        lightNode.runAction(decreaseAction) { [weak self] in
            self?.isLightActive = false // Mark light as inactive after fading out
            lightNode.light?.intensity = self?.originalLightIntensity ?? 0 // Ensure it resets to original
        }
    }
    
    
    private func loadSounds() {
        if let echoSoundURL = Bundle.main.url(forResource: "EcholocationSound", withExtension: "mp3") {
            do {
                echoAudioPlayer = try AVAudioPlayer(contentsOf: echoSoundURL)
                echoAudioPlayer?.prepareToPlay() // Prepare to play
            } catch {
                print("Error loading sound: \(error)")
            }
        } else {
            print("Sound file not found")
        }
        
        if let stepSoundURL = Bundle.main.url(forResource: "step", withExtension: "mp3") {
            do {
                stepAudioPlayer = try AVAudioPlayer(contentsOf: stepSoundURL)
                stepAudioPlayer?.prepareToPlay() // Prepare to play
            } catch {
                print("Error loading step sound: \(error)")
            }
        } else {
            print("Sound step file not found")
        }
    }

    private func playEchoSound() {
        guard let echoAudioPlayer = echoAudioPlayer else {
            return
        }

        if !echoAudioPlayer.isPlaying {
            echoAudioPlayer.play() // Play the sound
        }
    }

    private func playStepSound() {
        guard let stepAudioPlayer = stepAudioPlayer else {
            return
        }

        if !stepAudioPlayer.isPlaying {
            stepAudioPlayer.play() // Start playing the sound
        }
    }
    
    private func stopStepSound() {
        guard let stepAudioPlayer = stepAudioPlayer else {
            stepAudioPlayer?.stop() // Stop if currently playing
            return
        }
    }

    private func addPlayerPhysicsBody() {
          if playerNode.physicsBody == nil {
              // Ensure the player node has a physics body initialized correctly
              playerNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: playerNode, options: nil))

              guard let playerPhysicsBody = playerNode.physicsBody else {
                  print("Error: Player physics body is nil after initialization")
                  return
              }

              // Set mass, category, collision, and contact test bit masks
              playerPhysicsBody.mass = 1.0 // Set a lower mass for better movement control
  //            playerPhysicsBody.friction = 0.5 // Adjust friction as needed
              playerPhysicsBody.restitution = 1.0 // No bounciness

              playerPhysicsBody.isAffectedByGravity = false
              // Set up collision and contact masks
              playerPhysicsBody.categoryBitMask = 1  // Define a bitmask for the player
              playerPhysicsBody.collisionBitMask = 2 // Collides with walls/floor
              playerPhysicsBody.contactTestBitMask = 2 // Test for contact with walls
              
              // Now call the method to setup walls physics
              setupWallPhysicsBodies()
          }
      }

    private func setupWallPhysicsBodies() {
          // Loop through your walls and apply physics bodies
          for node in playerNode.parent?.childNodes ?? [] {
              if node.name?.contains("wall") == true /*|| node.name?.contains("floor")  == true */{
                  print("wall")
                  node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
                  node.physicsBody?.categoryBitMask = 2  // Wall category
                  node.physicsBody?.collisionBitMask = 1  // Collides with player
                  node.physicsBody?.contactTestBitMask = 1
              }
          }
      }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
          print("Player collided with wall or floor")

          let nodeA = contact.nodeA
          let nodeB = contact.nodeB

          // Check for collision between player and walls/floor
          if (nodeA.physicsBody?.categoryBitMask == 1 && nodeB.physicsBody?.categoryBitMask == 2) ||
             (nodeB.physicsBody?.categoryBitMask == 1 && nodeA.physicsBody?.categoryBitMask == 2) {
              print("Player collided with wall or floor")
              
              // Stop player movement by applying a zero velocity
              let playerNode = (nodeA.physicsBody?.categoryBitMask == 1) ? nodeA : nodeB
              if let playerPhysicsBody = playerNode.physicsBody {
                  // Reset player position to last known safe position
                  if let safePosition = lastSafePosition {
                      playerNode.position = safePosition
                      playerNode.physicsBody?.velocity = SCNVector3Zero
                  }
                  
                  // Adjust friction temporarily
                  playerPhysicsBody.friction = 0.5 // Lower friction for easier movement post-collision
                  
                  // Reset joystick direction only if not touching the joystick
                  joystickComponent?.resetJoystick()
              }
          }
      }
    
    func movePlayer(to position: SCNVector3, duration: TimeInterval, completion: @escaping () -> Void) {
        movingProgramatically = true
        let playerNode = playerNode
        let moveAction = SCNAction.move(to: position, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        playerNode.runAction(moveAction) {
            self.movingProgramatically = false
            completion()
        }
    }
}

// SCNVector3 Operators
func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func *(vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

// Utility extension for vector math
extension SCNVector3 {
    // Length (magnitude) of the vector
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
    }
    
    // Normalized vector (unit vector in the same direction)
    func normalized() -> SCNVector3 {
        let len = length()
        return len > 0 ? SCNVector3(x / len, y / len, z / len) : SCNVector3(0, 0, 0)
    }
}

func normalizeVector(_ vector: SCNVector3) -> SCNVector3 {
    let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
    guard length != 0 else { return SCNVector3Zero }
    return SCNVector3(vector.x / length, vector.y / length, vector.z / length)
}
