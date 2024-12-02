//  Scene7.swift

import SceneKit
import UIKit
import AVFoundation
import AVKit

class Scene7: SCNScene, SCNPhysicsContactDelegate {
    var playerEntity: PlayerEntity!
    var cameraComponent: CameraComponent!
    var joystickComponent: VirtualJoystickComponent!
    var cameraNode: SCNNode!
    var lightNode: SCNNode!
    var necklaceNode: SCNNode!
    
    var grandmaNode: SCNNode?
    var grandmaEntity: NPCEntity!
    var doorCloseNode : SCNNode?
    
    var objCakeNode: SCNNode! // Add a reference for Obj_Cake_003
    let proximityDistance: Float = 150.0 // Define a proximity distance
    
    weak var scnView: SCNView?
    var puzzleBackground: UIView?
    var playButton: UIButton? // Store a reference to the play button
    
    var isPuzzleDisplayed: Bool = false
    var isGameCompleted: Bool = false // Track if the game is completed
    
    var pianoKeys: [UIButton] = [] // Store piano keys
    var audioPlayer: AVAudioPlayer? // To play piano sounds
    var userPlayedNotes: [String] = [] // Store user input notes
    let targetMelody: [String] = ["Upper_Mi", "La", "Si", "Upper_Do", "Upper_Re", "Upper_Mi", "Upper_Do", "Upper_Mi"] // Target melody to match
    var blackKeys: [UIView] = []
    var targetIndex = 0
    
    var hintButton: UIButton!
    var hintTimer: Timer?
    var containerView: UIView?
    var progressBar: UIView!
    
    
    var correctPassword = "0324" // The correct password
    var enteredPassword = "" // Store user input password
    var numberPadContainer: UIView?
    var circles: [UIView] = []
    
    var timer: Timer?
    var timeRemaining: Int = 10 // 5 minutes in seconds
    var timerLabel: UILabel!
    
    var musicBoxNode: SCNNode!
    var phoneNode: SCNNode!
    var isPhonePuzzleCompleted = false
    var isPianoPuzzleCompleted = false
    
    var isPlayingPiano = false
    var isOpenPhone = false
    
    var isSwanLakePlaying = false
    
    var musicBoxPlayer: AVAudioPlayer?
    var grandmaAudioPlayer: AVAudioPlayer?
    var jumpscarePlayer: AVAudioPlayer?
    
    var isGrandmaFinishedTalking = false
    var isGrandmaisTalking = false
    
    var RingtonePlayer: AVAudioPlayer?
    
    let transitionTriggerPosition = SCNVector3(-83.414, 507.713, 113.845)
    let triggerDistance: Float = 80.0
    
    init(lightNode: SCNNode) {
        GameViewController.joystickComponent.showJoystick()
        
        super.init()
        self.lightNode = lightNode
        scnView?.pointOfView = cameraNode
        
        // Load the house scene from the Scenes folder
        guard let houseScene = SCNScene(named: "scene7.scn") else {
            fatalError("Error: Scene named 'scene7.scn' not found")
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
        
        if let muffledNode = rootNode.childNode(withName: "muffledRain", recursively: true) {
            attachAudio(to: muffledNode, audioFileName: "muffledRain.wav", volume: 0.5, delay: 0)
        }
        
        // Add player node to the GameScene's rootNode
        rootNode.addChildNode(playerNode)
        
        grandmaNode = rootNode.childNode(withName: "grandma", recursively: true)
        grandmaNode?.isHidden = true
        
        doorCloseNode = rootNode.childNode(withName: "door_close", recursively: true)
        
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
        
        musicBoxNode = rootNode.childNode(withName: "musicBox", recursively: true)
        
        phoneNode = rootNode.childNode(withName: "phone", recursively: true)
        
        setupPianoKeys()
        
        applyCustomFont(to: candleLabel, fontSize: 14)
        applyCustomFont(to: FailLabel, fontSize: 14)
        
        self.physicsWorld.contactDelegate = self
    }
    
    func displayNumberPad(on view: UIView) {
        isOpenPhone = true
        
        // Create the main container for the number pad
        let containerHeight: CGFloat = 400
        numberPadContainer = UIView(frame: CGRect(x: 0, y: (view.bounds.height - containerHeight) / 2, width: view.bounds.width, height: containerHeight))
        numberPadContainer?.backgroundColor = UIColor.clear
        view.addSubview(numberPadContainer!)
        
        // Add iPhoneBezel image behind the LockScreen and PasscodeScreen
        let bezelImageView = UIImageView(image: UIImage(named: "iPhoneBezel"))
        bezelImageView.contentMode = .scaleAspectFit
        bezelImageView.frame = numberPadContainer!.bounds
        numberPadContainer?.addSubview(bezelImageView)  // Add bezel first
        
        // Add LockScreen image initially with aspect fit
        let lockScreenImageView = UIImageView(image: UIImage(named: "LockScreenMusic"))
        lockScreenImageView.contentMode = .scaleAspectFit
        lockScreenImageView.frame = numberPadContainer!.bounds
        numberPadContainer?.addSubview(lockScreenImageView)  // Add lock screen on top of bezel
        
        // Play SwanLakeRingtone audio
        guard let audioUrl = Bundle.main.url(forResource: "SwanLakeRingtone", withExtension: "MP3") else { return }
        do {
            RingtonePlayer = try AVAudioPlayer(contentsOf: audioUrl)
            RingtonePlayer?.play()
        } catch {
            print("Error playing audio: \(error)")
        }
        
        // Delay to switch from LockScreen to PasscodeScreen after audio finishes
        DispatchQueue.main.asyncAfter(deadline: .now() + RingtonePlayer!.duration) {
            // Fade out the lock screen
            UIView.animate(withDuration: 0.5, animations: {
                lockScreenImageView.alpha = 0
            }) { _ in
                // Change LockScreen to PasscodeScreen
                lockScreenImageView.image = UIImage(named: "PasscodeScreen")
                
                // Fade in the passcode screen
                UIView.animate(withDuration: 0.5, animations: {
                    lockScreenImageView.alpha = 1
                }, completion: { _ in
                    // Create an inner container for the number pad and circles
                    let innerNumberPadContainer = UIView(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: 340))
                    innerNumberPadContainer.backgroundColor = UIColor.clear
                    self.numberPadContainer?.addSubview(innerNumberPadContainer)
                    
                    // Add circles for password input indicators
                    let circleSize: CGFloat = 15
                    let spacing: CGFloat = 10
                    let startX = (view.bounds.width - (circleSize * 4 + spacing * 3)) / 2
                    
                    for i in 0..<4 {
                        let circle = UIView(frame: CGRect(x: startX + CGFloat(i) * (circleSize + spacing), y: 10, width: circleSize, height: circleSize))
                        circle.layer.cornerRadius = circleSize / 2
                        circle.layer.borderColor = UIColor.white.cgColor
                        circle.layer.borderWidth = 2
                        circle.backgroundColor = UIColor.clear
                        self.circles.append(circle)
                        innerNumberPadContainer.addSubview(circle)
                    }
                    
                    // Create buttons for numbers 0-9
                    let buttonTitles = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
                    let buttonSize: CGFloat = 40
                    
                    for (index, title) in buttonTitles.enumerated() {
                        let button = UIButton(type: .system)
                        button.setTitle(title, for: .normal)
                        button.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                        button.setTitleColor(.white, for: .normal)
                        button.layer.borderColor = UIColor.white.cgColor
                        button.layer.borderWidth = 2
                        button.layer.cornerRadius = buttonSize / 2
                        button.backgroundColor = .clear
                        button.alpha = 0  // Set initial alpha to 0 for fade-in effect
                        button.addTarget(self, action: #selector(self.numberButtonTapped(_:)), for: .touchUpInside)
                        
                        let row = index / 3
                        let col = index % 3
                        
                        if title == "0" {
                            button.frame = CGRect(
                                x: (view.bounds.width - buttonSize) / 2,
                                y: CGFloat(row) * (buttonSize + spacing) + 50,
                                width: buttonSize,
                                height: buttonSize
                            )
                        } else {
                            button.frame = CGRect(
                                x: CGFloat(col) * (buttonSize + spacing) + (view.bounds.width - (buttonSize * 3 + spacing * 2)) / 2,
                                y: CGFloat(row) * (buttonSize + spacing) + 50,
                                width: buttonSize,
                                height: buttonSize
                            )
                        }
                        
                        innerNumberPadContainer.addSubview(button)
                        
                        // Fade in each button
                        UIView.animate(withDuration: 0.5, delay: 0.1 * Double(index), options: [.curveEaseIn], animations: {
                            button.alpha = 1
                        }, completion: nil)
                    }
                })
            }
        }
    }
    
    
    @objc func numberButtonTapped(_ sender: UIButton) {
        guard let number = sender.title(for: .normal) else { return }
        
        // Add tapped number to the entered password
        enteredPassword += number
        print("Entered Password: \(enteredPassword)") // Debugging output
        
        // Update circles
        updateCircles()
        
        // Automatically check after entering 4 numbers
        if enteredPassword.count == 4 {
            checkPassword()
        }
    }
    
    func updateCircles() {
        for (index, circle) in circles.enumerated() {
            if index < enteredPassword.count {
                circle.backgroundColor = .white // Change color to white
            } else {
                circle.backgroundColor = .clear // Reset color
            }
        }
    }
    
    func checkPassword() {
        if enteredPassword == correctPassword {
            print("Password correct! Unlocking...")
            // Trigger puzzle completion or transition
            triggerUnlockSuccess()
        } else {
            print("Incorrect password. Try again.")
            // Fill the circles and reset after 1 second
            fillCircles()
            enteredPassword = ""
        }
    }
    
    func shakeCircles() {
        // Store original positions for reset
        let originalPositions = circles.map { $0.center }
        
        for (index, circle) in circles.enumerated() {
            // Add shake animation
            let shakeAnimation = CAKeyframeAnimation(keyPath: "position")
            shakeAnimation.values = [
                NSValue(cgPoint: CGPoint(x: circle.center.x - 10, y: circle.center.y)),
                NSValue(cgPoint: CGPoint(x: circle.center.x + 10, y: circle.center.y)),
                NSValue(cgPoint: CGPoint(x: circle.center.x - 10, y: circle.center.y))
            ]
            shakeAnimation.autoreverses = true
            shakeAnimation.duration = 0.1
            shakeAnimation.repeatCount = 3
            shakeAnimation.isRemovedOnCompletion = false
            
            circle.layer.add(shakeAnimation, forKey: "position")
            
            // Ensure final reset to original position
            DispatchQueue.main.asyncAfter(deadline: .now() + shakeAnimation.duration * Double(shakeAnimation.repeatCount)) {
                circle.center = originalPositions[index]
            }
        }
        
        // Reset circles after shake
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.resetCircles()
        }
    }
    
    
    func fillCircles() {
        // Fill all circles with white
        for circle in circles {
            UIView.animate(withDuration: 0.5, animations: {
                circle.backgroundColor = .white // Change color to white
            })
        }
        
        // Wait for 0.5 seconds then shake the circles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shakeCircles() // Call shake function
        }
    }
    
    func resetCircles() {
        for circle in circles {
            circle.backgroundColor = .clear // Reset color
        }
    }
    
    func moveGrandma(completion: @escaping () -> Void) {
        guard let grandmaNode = grandmaNode else { return }
        
        // Hide the grandmaNode before moving
        grandmaNode.isHidden = true // Hide grandma before moving
        
        let targetPosition = SCNVector3(x: -254.221, y: 104.194, z: 36.647)
        let moveAction = SCNAction.move(to: targetPosition, duration: 0.5)
        
        grandmaEntity.activateEcholocation()
        
        grandmaNode.runAction(moveAction) {
            completion()
        }
    }
    
    
    
    func triggerUnlockSuccess() {
        // Remove the number pad container after unlocking
        numberPadContainer?.removeFromSuperview()
        
        isOpenPhone = false
        isPhonePuzzleCompleted = true
        
        // Hide the joystick while the video is playing
        GameViewController.joystickComponent.hideJoystick()
        
        // Set up video playback on unlock
        guard let numberPadFrame = numberPadContainer?.frame else { return }
        let videoContainer = UIView(frame: numberPadFrame)
        videoContainer.backgroundColor = UIColor.clear // Set to clear for video view
        
        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            keyWindow.addSubview(videoContainer)
        }
        
        // Prepare the video
        guard let videoURL = Bundle.main.url(forResource: "KiranaDiary", withExtension: "mp4") else {
            print("Video file not found")
            return
        }
        
        // Create an AVPlayer
        let player = AVPlayer(url: videoURL)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoContainer.bounds
        playerLayer.videoGravity = .resizeAspect
        videoContainer.layer.addSublayer(playerLayer)
        player.volume = 1.0
        
        // Play the video
        player.play()
        
        // Add observer to remove video and show joystick once finished
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            
            // Stop and remove video
            player.pause()
            playerLayer.removeFromSuperlayer()
            videoContainer.removeFromSuperview()
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            
            // Show the joystick again
            GameViewController.joystickComponent.showJoystick()
            
            print("Video playback completed, joystick is now visible.")
        }
    }
    
    private func updateCameraPositionAndOrientation() {
        guard let playerNode = playerEntity.playerNode else { return }
        
        // Set the camera position to be relative to the player position
        // Adjust the offset based on how you want the camera positioned behind/above the player
        let cameraOffset = SCNVector3(0, 1.5, -5) // Example offset to place the camera behind the player
        cameraNode.position = playerNode.position + cameraOffset // Update camera position
        
        // Ensure the camera faces the same direction as the player
        cameraNode.eulerAngles = playerNode.eulerAngles
    }
    
    func setupPianoKeys() {
        // Define notes from middle Do to upper Mi and their corresponding numbers
        let notes = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si", "Upper_Do", "Upper_Re", "Upper_Mi"]
        let noteNumbers = ["1", " ", " ", " ", "5", " ", " ", "1̇", "2̇", "3̇"] // Numbers under white keys
        
        let keyWidth: CGFloat = 50
        let keyHeight: CGFloat = 150
        let spacing: CGFloat = 0
        
        // Clear existing keys to avoid duplication
        pianoKeys.removeAll()
        blackKeys.removeAll()
        
        for (index, note) in notes.enumerated() {
            let keyButton = UIButton(type: .system)
            
            // Set specific images or color for certain keys
            switch index {
            case 2, 5, 6:
                keyButton.setBackgroundImage(UIImage(named: "WhiteKeyz"), for: .normal)
            case 1:
                keyButton.setBackgroundImage(UIImage(named: "WhiteKeyz"), for: .normal)
            default:
                keyButton.setBackgroundImage(UIImage(named: "WhiteKeyz"), for: .normal)
            }
            
            // Set the note number as the button title
            keyButton.setTitle(noteNumbers[index], for: .normal)
            keyButton.setTitleColor(.black, for: .normal) // Set title color for visibility
            keyButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold) // Adjust font size and weight
            
            // Adjust the button's content vertical alignment to position the title lower
            keyButton.contentVerticalAlignment = .bottom
            
            keyButton.tag = index
            
            
            // Set frame for white key button
            keyButton.frame = CGRect(
                x: CGFloat(index) * (keyWidth + spacing),
                y: 0,
                width: keyWidth,
                height: keyHeight
            )
            print("Key Button Frame: \(keyButton.frame)")
            
            // Add black border
            keyButton.layer.borderColor = UIColor.black.cgColor
            keyButton.layer.borderWidth = 1.5 // Adjust width as needed
            
            
            // Attach touch event
            keyButton.addTarget(self, action: #selector(playPianoKey(_:)), for: .touchUpInside)
            keyButton.addTarget(self, action: #selector(debugPrint(_:)), for: .touchUpInside)
            
            // Append key to piano keys array
            pianoKeys.append(keyButton)
        }
        
        // Create black keys (non-clickable)
        let blackKeyWidth = keyWidth * 0.6
        let blackKeyHeight = keyHeight * 0.6
        let blackKeyPositions: [CGFloat] = [0.85, 1.75, 3.35, 4.25, 5.15, 6.75, 7.60] // Adjusted positions
        
        // Load the black key image
        if let blackKeyImage = UIImage(named: "BlackKeyz") {
            for position in blackKeyPositions {
                let blackKey = UIImageView(frame: CGRect(x: position * keyWidth - blackKeyWidth / 2, y: 0, width: blackKeyWidth, height: blackKeyHeight))
                blackKey.image = blackKeyImage
                // blackKey.contentMode = .scaleAspectFit // Ensures the image fits the key
                blackKeys.append(blackKey) // Add to an array for later display
            }
        }
        
    }
    
    @objc func debugPrint(_ sender: UIButton) {
        print("Debug: \(notes[sender.tag]) pressed")
    }
    
    func displayPianoPuzzle(on view: UIView) {
        // Clear existing container view if it exists
        containerView?.removeFromSuperview()
        
        let screenWidth = view.bounds.width
        
        // Define heights for each component
        let partitureHeight: CGFloat = 130
        let progressBarHeight: CGFloat = 50
        let pianoHeight: CGFloat = 150
        let pianoTopPadding: CGFloat = 10 // Define top padding for the piano
        
        // Calculate the total height of the container view that will hold all components
        let totalHeight = partitureHeight + progressBarHeight + pianoHeight + 20 // Adjust spacing as needed
        
        // Create a container view centered vertically and horizontally in the main view
        let containerWidth: CGFloat = screenWidth / 2 + 50
        containerView = UIView(frame: CGRect(
            x: (view.bounds.width - containerWidth) / 2, // Center horizontally
            y: (view.bounds.height - totalHeight) / 2, // Center vertically
            width: containerWidth, // Set container width
            height: totalHeight // Use the calculated height for the puzzle
        ))
        view.addSubview(containerView!)
        
        // Set the background color to a semi-transparent black
        containerView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Add rounded corners
        containerView?.layer.cornerRadius = 20 // Adjust the radius as needed
        containerView?.layer.masksToBounds = true
        
        // Add the partiture view at the top of the container view
        let partitureView = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: containerWidth, // Use container width
            height: partitureHeight
        ))
        partitureView.backgroundColor = .clear
        containerView?.addSubview(partitureView)
        
        setupTimer() // Call the timer setup
        
        let partitureImage = UIImageView(image: UIImage(named: "MusicSheetHint")) // Replace with actual image name
        partitureImage.contentMode = .scaleAspectFit
        partitureImage.frame = partitureView.bounds
        partitureView.addSubview(partitureImage)
        
        // Add the progress circles below the partiture in the container view
        setupProgressCircles(on: containerView!, below: partitureView)
        
        // Add the piano view below the progress circles in the container view
        let pianoViewWidth = CGFloat(pianoKeys.count) * 45 // Width for each key
        let pianoViewYPosition = (progressCircles.first?.frame.maxY ?? partitureView.frame.maxY) + 10 + pianoTopPadding // Adjusted for top padding
        
        let pianoView = UIView(frame: CGRect(
            x: (containerWidth - pianoViewWidth), // Center horizontally in the container view
            y: pianoViewYPosition,
            width: pianoViewWidth,
            height: pianoHeight
        ))
        pianoView.backgroundColor = .clear
        containerView?.addSubview(pianoView)
        
        // Add white keys to the piano
        for (index, key) in pianoKeys.enumerated() {
            key.frame = CGRect(
                x: CGFloat(index) * (40 + 2),
                y: 0,
                width: 40,
                height: 130
            )
            pianoView.addSubview(key)
        }
        
        // Add black keys to the piano
        for blackKey in blackKeys {
            blackKey.frame.size = CGSize(width: 24, height: 80)
            pianoView.addSubview(blackKey)
        }
        
        isPuzzleDisplayed = true
        isPlayingPiano = true
    }
    
    func setupTimer() {
        timeRemaining = 120
        timerLabel = UILabel(frame: CGRect(x: containerView!.frame.maxX + 10, y: containerView!.frame.midY - 25, width: 100, height: 50))
        timerLabel.textColor = .white
        timerLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        timerLabel.textAlignment = .center
        timerLabel.text = formatTime(timeRemaining)
        applyCustomFont(to: timerLabel, fontSize: 20)
        if let parentView = containerView?.superview {
            parentView.addSubview(timerLabel)
        }
        print("Timer started with \(timeRemaining) seconds")
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }
    
    @objc func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
            timerLabel.text = formatTime(timeRemaining)
        } else {
            timer?.invalidate() // Stop the timer
            timer = nil
            resetPianoPuzzle() // Dismiss the puzzle when the time is up
            print("Timer ended. Puzzle dismissed due to timeout.")
        }
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    func resetPianoPuzzle() {
        // Dismiss the piano puzzle view first
        containerView?.removeFromSuperview() // Remove the container view from the superview
        containerView = nil // Optionally, set to nil to avoid dangling references
        
        // Reset the timer
        timeRemaining = 120
        timerLabel.text = formatTime(timeRemaining)
        timerLabel.removeFromSuperview()
        
        // Reset melody check
        resetMelodyCheck()
        
        // Reset progress circles
        for circle in progressCircles {
            circle.image = UIImage(named: "MusicNote_Null") // Reset each circle to the empty note image
        }
        
        // Optionally, reset the piano keys appearance
        for key in pianoKeys {
            key.alpha = 1.0 // Reset opacity if you have a fading effect
        }
        
        isPlayingPiano = false
        isGameCompleted = false
        
        // Show the fail label if the puzzle has not been completed successfully
        if isPianoPuzzleCompleted == false {
            if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                self.displayFailLabel(on: keyWindow)
            }
        }
    }
    
    // Define the full list of notes
    let notes = ["Do", "Re", "Mi", "Fa", "Sol", "La", "Si", "Upper_Do", "Upper_Re", "Upper_Mi"]
    @objc func playPianoKey(_ sender: UIButton) {
        
        guard sender.tag < notes.count else { return }
        
        let note = notes[sender.tag]
        playSound(named: note)
        
        print("Pressed Note: \(note)")
        
        if note == targetMelody[targetIndex] {
            userPlayedNotes.append(note)
            print("Current Sequence: \(userPlayedNotes)")
            
            // Update the progress bar
            updateProgressBar()
            
            targetIndex += 1
            
            if targetIndex == targetMelody.count {
                print("Melody completed successfully!")
                triggerPianoPuzzleCompletionTransition()
                // Optional: Call reset only if needed
            }
        } else {
            print("Pressed Note: \(note) does not match. Resetting input.")
            // Call reset only here if necessary
            resetMelodyCheck() // Reset only if the note is incorrect
        }
    }
    
    func resetMelodyCheck() {
        userPlayedNotes.removeAll()
        targetIndex = 0
        print("Current Sequence: \(userPlayedNotes)")
        
        // Reset all progress circles to MusicNote_Null
        for circle in progressCircles {
            circle.image = UIImage(named: "MusicNote_Null")
        }
    }
    
    // Property to hold the progress circle views
    var progressCircles: [UIImageView] = []
    
    func setupProgressCircles(on containerView: UIView, below partitureView: UIView) {
        // Clear existing progress circles
        for circle in progressCircles {
            circle.removeFromSuperview()
        }
        progressCircles.removeAll() // Clear the array holding the circles
        
        let numberOfCircles = 8 // Example number of circles
        let circleDiameter: CGFloat = 40 // Example diameter for circles
        let circleSpacing: CGFloat = 10 // Space between circles
        
        for i in 0..<numberOfCircles {
            let circle = UIImageView(frame: CGRect(
                x: (containerView.bounds.width - (circleDiameter * CGFloat(numberOfCircles) + circleSpacing * CGFloat(numberOfCircles - 1))) / 2 + CGFloat(i) * (circleDiameter + circleSpacing),
                y: partitureView.frame.maxY + 10,
                width: circleDiameter,
                height: circleDiameter
            ))
            circle.image = UIImage(named: "MusicNote_Null") // Initial image for the circle
            progressCircles.append(circle)
            containerView.addSubview(circle)
        }
    }
    
    func updateProgressBar() {
        print("Updating progress bar. Current played notes: \(userPlayedNotes)")
        for (index, progressImage) in progressCircles.enumerated() {
            if index < userPlayedNotes.count {
                progressImage.image = UIImage(named: "MusicNote_Full")
            } else {
                progressImage.image = UIImage(named: "MusicNote_Null")
            }
        }
    }
    
    func playSound(named note: String) {
        guard let soundURL = Bundle.main.url(forResource: note, withExtension: "mp3") else {
            print("Sound file for \(note) not found")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Failed to play \(note): \(error)")
        }
    }
    
    func triggerPianoPuzzleCompletionTransition() {
        // Step 1: Animate each key in a wave pattern
        for (index, key) in pianoKeys.enumerated() {
            let delay = Double(index) * 0.05 // Delay between each key animation
            
            UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseInOut, animations: {
                key.setBackgroundImage(nil, for: .normal)
                key.backgroundColor = .white // Reset background color
                key.setTitleColor(.clear, for: .normal) // Hide text color for effect
            }, completion: nil)
        }
        isPianoPuzzleCompleted = true
        timerLabel.removeFromSuperview()
        isPlayingPiano = true
        isGameCompleted = true
        toggleGlowEffect(on: musicBoxNode, isEnabled: false)
        
        // Step 2: Load and play the MusicBox audio
        if let musicBoxURL = Bundle.main.url(forResource: "MusicBox", withExtension: "MP3") {
            do {
                musicBoxPlayer = try AVAudioPlayer(contentsOf: musicBoxURL)
                musicBoxPlayer?.play()
                
                isSwanLakePlaying = true
                
                // Delay to call displaycandleLabel function
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                        self.displaycandleLabel(on: keyWindow)
                    }
                }
            } catch {
                print("Error loading MusicBox audio: \(error)")
            }
        }
        
        // Step 3: After all key animations, fade out the puzzle view
        let totalAnimationDuration = Double(pianoKeys.count) * 0.05 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalAnimationDuration) {
            if let containerView = self.containerView {
                UIView.animate(withDuration: 0.5, animations: {
                    containerView.alpha = 0 // Fade out effect
                }) { _ in
                    containerView.removeFromSuperview() // Remove from superview after fade out
                    self.isPuzzleDisplayed = false // Update state
                }
            }
            
            // Step 4: Display grandma and perform final animation sequence after audio ends
            DispatchQueue.main.asyncAfter(deadline: .now() + (self.musicBoxPlayer?.duration ?? 0)) {
                
                self.isSwanLakePlaying = false
                
                // Hide the joystick while grandma speaks
                GameViewController.joystickComponent.joystickView.isHidden = true
                
                // Create a black semi-transparent overlay view
                let overlayView = UIView(frame: UIScreen.main.bounds)
                overlayView.backgroundColor = UIColor.black
                overlayView.alpha = 0.0 // Start transparent
                if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                    keyWindow.addSubview(overlayView)
                }
                
                UIView.animate(withDuration: 1.5, animations: {
                    overlayView.alpha = 1.0 // Fade in the overlay
                }) { _ in
                    // Show grandma node
                    self.grandmaNode?.isHidden = false // Show grandma node
                    self.doorCloseNode?.isHidden = true
                    self.isGrandmaFinishedTalking = false
                    self.isGrandmaisTalking = true
                    self.addBlueFireAnimationNode()
                    
                    
                    // Move player to new position
                    let newPosition = SCNVector3(-395.591, 104.963, 42.888)
                    self.playerEntity.playerNode?.position = newPosition
                    
                    // Set the camera to face the initial angles (180, 0, 180)
                    self.cameraNode.eulerAngles = SCNVector3(0, CGFloat(3 * Double.pi / 2), 0) // Y rotation 180 degrees
                    
                    // Delay the camera rotation by 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Add an action to rotate the camera 180 degrees over 1 second
                        let cameraRotationAction = SCNAction.rotateBy(x: 0, y: CGFloat(3 * Double.pi / 2), z: 0, duration: 0.3)
                        cameraRotationAction.timingMode = .easeInEaseOut
                        
                        // Run the action on the camera node
                        self.cameraNode.runAction(cameraRotationAction) { [self] in
                            // Play the jumpscare audio
                            if let jumpscareURL = Bundle.main.url(forResource: "jumpascareGrandma", withExtension: "MP3") {
                                do {
                                    jumpscarePlayer = try AVAudioPlayer(contentsOf: jumpscareURL)
                                    jumpscarePlayer?.volume = 1.0
                                    jumpscarePlayer?.play()
                                    isGrandmaFinishedTalking = false
                                } catch {
                                    print("Error loading jumpscare4 audio: \(error)")
                                }
                            }
                            
                            // Set the final orientation after rotation
                            let finalEulerAngles = SCNVector3(0, CGFloat(Double.pi / 2), 0) // Adjust to desired final angles
                            self.cameraNode.eulerAngles = finalEulerAngles
                            
                            // Step 5: Play grandma's audio after rotation and jumpscare
                            if let grandmaAudioURL = Bundle.main.url(forResource: "s7-grandma", withExtension: "MP3") {
                                do {
                                    self.grandmaAudioPlayer = try AVAudioPlayer(contentsOf: grandmaAudioURL)
                                    grandmaAudioPlayer?.play()
                                    
                                    // Print "grandma audio finished" after the audio ends (approximately 4 seconds)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                        print("grandma audio finished")
                                        isGrandmaFinishedTalking = true
                                        isGrandmaisTalking = false
                                        
                                        // Place the code here to reset the camera and re-enable controls
                                        if let playerNode = self.playerEntity.playerNode {
                                            self.cameraComponent.resetCameraOrientation(to: playerNode)
                                        }
                                        
                                        // Show the joystick again after grandma's speech
                                        GameViewController.joystickComponent.joystickView.isHidden = false
                                    }
                                } catch {
                                    print("Error loading s7-grandma audio: \(error)")
                                }
                            }
                        }
                    }
                    
                    // Fade back out the overlay after a short delay
                    UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                        overlayView.alpha = 0.0 // Fade out the overlay
                    }) { _ in
                        overlayView.removeFromSuperview() // Remove the overlay
                    }
                }
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
    }
    
    func displaycandleLabel(on view: UIView) {
        candleLabel.text = "Candle and keys are obtained!"
        view.addSubview(candleLabel)
        
        // Position the candle label above the center of the screen
        let offsetFromTop: CGFloat = 170
        candleLabel.frame = CGRect(
            x: (view.bounds.width - 250) / 2,
            y: (view.bounds.height) / 2 - offsetFromTop,
            width: 255,
            height: 25
        )
        // Fade in the label
        UIView.animate(withDuration: 0.5) {
            self.candleLabel.alpha = 1.0
        }
        
        // Create and display the image "CandleAndKeys"
        let candleAndKeysImageView = UIImageView(image: UIImage(named: "CandleAndKeys"))
        candleAndKeysImageView.contentMode = .scaleAspectFit
        candleAndKeysImageView.frame = CGRect(
            x: (view.bounds.width - 350) / 2, // Adjust width as necessary
            y: (view.bounds.height - 350) / 2, // Adjust height as necessary
            width: 350, // Set desired width
            height: 350  // Set desired height
        )
        candleAndKeysImageView.alpha = 0.0 // Start with hidden image
        view.addSubview(candleAndKeysImageView)
        
        // Fade in the image
        UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
            candleAndKeysImageView.alpha = 1.0
        }, completion: nil)
        
        // Fade out the label after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            UIView.animate(withDuration: 0.5) {
                self.candleLabel.alpha = 0.0
                candleAndKeysImageView.alpha = 0.0 // Optional: fade out the image too
            }
        }
    }
    
    // Define the label for displaying the message
    private let candleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.alpha = 0.0
        return label
    }()
    
    func displayFailLabel(on view: UIView) {
        FailLabel.text = "You failed! Try again!"
        view.addSubview(FailLabel)
        
        // Position the camera instruction label above the center of the screen
        let offsetFromTop: CGFloat = 170
        FailLabel.frame = CGRect(
            x: (view.bounds.width - 250) / 2,
            y: (view.bounds.height) / 2 - offsetFromTop,
            width: 255,
            height: 25
        )
        // Fade in the label
        UIView.animate(withDuration: 0.5) {
            self.FailLabel.alpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 0.5) {
                self.FailLabel.alpha = 0.0
            }
        }
    }
    
    // Define the label for displaying the message
    private let FailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.alpha = 0.0
        return label
    }()
    
    private func applyCustomFont(to label: UILabel, fontSize: CGFloat) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: fontSize) {
            label.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
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
        
        // Measure distances to each puzzle object
        let distanceToMusicBox = playerNode.position.distance(to: musicBoxNode.position)
        let distanceToPhone = playerNode.position.distance(to: phoneNode.position)
        
        // Check if the piano puzzle is completed
        if isPianoPuzzleCompleted {
            // Disable glow on both nodes if the piano puzzle is finished
            toggleGlowEffect(on: phoneNode, isEnabled: false)
            toggleGlowEffect(on: musicBoxNode, isEnabled: false)
            interactButton.isHidden = true // Hide interact button since the puzzle is complete
            return
        }
        
        if !isPhonePuzzleCompleted {
            // Only allow the phone to glow at first
            if distanceToPhone < proximityDistance {
                toggleGlowEffect(on: phoneNode, isEnabled: true)
                interactButton.setTitle("Phone", for: .normal)
                interactButton.isHidden = false
            } else {
                toggleGlowEffect(on: phoneNode, isEnabled: false)
                interactButton.isHidden = true
            }
            
            // Ensure the music box does not glow until the phone puzzle is completed
            toggleGlowEffect(on: musicBoxNode, isEnabled: false)
            
        } else {
            // After the phone puzzle is completed, allow the music box to glow
            if distanceToMusicBox < proximityDistance {
                toggleGlowEffect(on: musicBoxNode, isEnabled: true)
                interactButton.setTitle("Music Box", for: .normal)
                interactButton.isHidden = false
            } else {
                toggleGlowEffect(on: musicBoxNode, isEnabled: false)
                interactButton.isHidden = true
            }
            
            // Ensure the phone does not glow after its puzzle is completed
            toggleGlowEffect(on: phoneNode, isEnabled: false)
        }
    }
    
    // This function would be called when the piano puzzle is completed
    func completePianoPuzzle() {
        isPhonePuzzleCompleted = true
        isOpenPhone = true
        // Remove glow from music box and update the player to interact with the phone next
        toggleGlowEffect(on: phoneNode, isEnabled: false)
        print("puzzle completed! Phone puzzle is now active.")
    }
    
    func completePiano2Puzzle() {
        isPianoPuzzleCompleted = true
        // Remove glow from music box and update the player to interact with the phone next
        toggleGlowEffect(on: musicBoxNode, isEnabled: false)
        print("puzzle completed! Phone puzzle is now active.")
    }
    
    @objc func interactWithPhone() {
        isOpenPhone = true
        
    }
    
    func toggleGlowEffect(on node: SCNNode, isEnabled: Bool) {
        if isEnabled {
            node.categoryBitMask = 2 // Enable glow effect for the specified node
        } else {
            node.categoryBitMask = 1 // Disable glow effect for the specified node
        }
    }
    
    // Check if the player is close to the transition trigger point
    func checkProximityToTransition() -> Bool {
        guard let playerPosition = playerEntity.playerNode?.position else { return false }
        let distance = playerPosition.distance(to: transitionTriggerPosition)
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
