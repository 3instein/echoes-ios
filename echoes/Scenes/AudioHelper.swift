//  AudioHelper.swift

import SceneKit

class AudioHelper {
    static func loadAudio(named fileName: String, shouldLoop: Bool = false, volume: Float = 1.0) -> SCNAudioSource? {
        guard let audioSource = SCNAudioSource(fileNamed: fileName) else {
            print("Error loading audio file: \(fileName)")
            return nil
        }
        audioSource.loops = shouldLoop
        audioSource.shouldStream = false
        audioSource.volume = volume
        audioSource.load()
        return audioSource
    }

    static func attachAudio(to node: SCNNode, audioSource: SCNAudioSource?, volume: Float = 1.0) {
        guard let audioSource = audioSource else { return }
        audioSource.volume = volume
        let playAudioAction = SCNAction.playAudio(audioSource, waitForCompletion: false)
        node.runAction(playAudioAction)
    }
}
