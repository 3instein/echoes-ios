import GameplayKit
import SceneKit
import AVFoundation

class MovementComponent: GKComponent {
    let playerNode: SCNNode
    let movementSpeed: Float = 5
    var joystickComponent: VirtualJoystickComponent?
    var cameraNode: SCNNode?

    // Light node reference
    var lightNode: SCNNode?
    var originalLightIntensity: CGFloat = 25 // Default intensity
    var isLightActive = false // Track if light is active
    private var lightIncreaseDuration: TimeInterval = 0.5 // Reduced duration for increasing intensity
    private var lightDecreaseDuration: TimeInterval = 0.3 // Reduced duration for decreasing intensity
    private var lightTimer: Timer?
    private var lightTimerDelay: TimeInterval = 1.0 // Reduced delay before light starts dimming
    
    // Sound properties
    var audioPlayer: AVAudioPlayer?
    private var lastStepTime: Date?
    private let stepDelay: TimeInterval = 2.0 // Minimum delay between steps

    init(playerNode: SCNNode, cameraNode: SCNNode?, lightNode: SCNNode?) {
        self.playerNode = playerNode
        self.cameraNode = cameraNode
        self.lightNode = lightNode
        self.originalLightIntensity = lightNode?.light?.intensity ?? 25 // Set original intensity

        super.init()
        
        // Load sound
        loadSound()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime seconds: TimeInterval) {
        guard let joystick = joystickComponent, joystick.isTouching, let cameraNode = cameraNode else {
            return
        }

        let direction = joystick.direction
        let deltaTime = Float(seconds)

        // Calculate the camera's forward and right direction vectors
        let cameraTransform = cameraNode.transform
        let forwardVector = SCNVector3(cameraTransform.m31, cameraTransform.m32, cameraTransform.m33)
        let rightVector = SCNVector3(cameraTransform.m11, cameraTransform.m12, -cameraTransform.m13)

        // Scale direction by joystick input
        let forwardMovement = forwardVector * Float(direction.y) * movementSpeed * deltaTime
        let rightMovement = rightVector * Float(direction.x) * movementSpeed * deltaTime

        // Combine forward and right movement
        let movementVector = forwardMovement + rightMovement

        // Translate the player node based on the movement vector
        playerNode.localTranslate(by: movementVector)

        // Update light position to follow player
        updateLightPosition()

        // Check time since last step to play sound
        let currentTime = Date()
        if lastStepTime == nil || currentTime.timeIntervalSince(lastStepTime!) >= stepDelay {
            playSound() // Play sound if the delay has passed
            lastStepTime = currentTime // Update the last step time
        }

        // User is moving
        if !isLightActive {
            activateLightPulsing() // Activate light pulsing if not already active
        }
    }

    private func loadSound() {
        if let soundURL = Bundle.main.url(forResource: "EcholocationSound", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.prepareToPlay() // Prepare to play
                print("Sound loaded successfully")
            } catch {
                print("Error loading sound: \(error)")
            }
        } else {
            print("Sound file not found")
        }
    }

    private func playSound() {
        guard let audioPlayer = audioPlayer else {
            print("Audio player is nil")
            return
        }

        if audioPlayer.isPlaying {
            audioPlayer.stop() // Stop if already playing
            audioPlayer.currentTime = 0 // Reset to the beginning
        }
        
        do {
            try audioPlayer.play() // Try to play the sound
            print("Playing sound")
        } catch {
            print("Error playing sound: \(error)") // Handle playback errors
        }
    }

    private func updateLightPosition() {
        guard let lightNode = lightNode else { return }
        // Update the light position to follow the player
        lightNode.position = SCNVector3(playerNode.position.x, playerNode.position.y + 5, playerNode.position.z) // Adjust height as necessary
    }

    private func activateLightPulsing() {
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
            lightNode.light?.intensity = self?.originalLightIntensity ?? 100 // Ensure it resets to original
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
