//  EcholocationComponent.swift

import GameplayKit
import SceneKit
import AVFoundation

class EcholocationComponent: GKComponent {
    private let lightNode: SCNNode
    private var originalLightIntensity: CGFloat
    private var flashDuration: TimeInterval = 0.1 // Short flash duration
    private var resetDuration: TimeInterval = 0.2 // Quick fade back to normal
    private var isFlashing = false
    
    var echolocationSound: AVAudioPlayer?
    
    init(lightNode: SCNNode, originalIntensity: CGFloat = 75) {
        self.lightNode = lightNode
        self.originalLightIntensity = originalIntensity
        super.init()
        loadSound()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadSound() {
        guard let soundURL = Bundle.main.url(forResource: "EcholocationSound", withExtension: "mp3") else {
            print("Echolocation sound file not found")
            return
        }
        
        do {
            echolocationSound = try AVAudioPlayer(contentsOf: soundURL)
            echolocationSound?.prepareToPlay()
        } catch {
            print("Error loading echolocation sound: \(error)")
        }
    }
    
    func activateFlash() {
        guard !isFlashing else { return }
        isFlashing = true
        
        playEcholocationSound()
        
        // Ensure lightNode has a light component before manipulating intensity
        guard let light = lightNode.light else {
            print("No light attached to lightNode")
            return
        }
        
        // Flash the light: briefly increase intensity to simulate echolocation
        let flashAction = SCNAction.customAction(duration: flashDuration) { _, _ in
            light.intensity = self.originalLightIntensity + 1000
        }
        
        // Reset the light back to its original intensity
        let resetAction = SCNAction.customAction(duration: resetDuration) { _, _ in
            light.intensity = self.originalLightIntensity
        }
        
        let sequence = SCNAction.sequence([flashAction, resetAction])
        lightNode.runAction(sequence) { [weak self] in
            self?.isFlashing = false
        }
    }
    
    private func playEcholocationSound() {
        guard let echolocationSound = echolocationSound else {
            print("No echolocation sound loaded")
            return
        }
        
        if !echolocationSound.isPlaying {
            echolocationSound.play()
        }
    }
}
