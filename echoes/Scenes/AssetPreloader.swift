//  AssetPreloader.swift

import SceneKit

class AssetPreloader {
    static func preloadScene2(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene2.scn"
        let audioFiles = ["doorOpen.MP3", "doorClose.MP3", "s3-grandma.mp3", "s3-andra.mp3", "wind.wav", "crow.wav", "outsideRain.wav"]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScene4(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene4ely.scn"
        let audioFiles = ["woodenFloor.wav", "clockTicking.wav", "muffledRain.wav", "s4-andra.wav", "s4-grandma1.wav", "s4-grandma2.wav"]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScenes5and6(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene5and6ely.scn"
        let audioFiles = ["woodenFloor.wav", "clockTicking.wav", "muffledRain.wav", "s5-grandma.wav", "s5-andra.wav", "fallingCup.mp3"]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    // Generalized function to preload both scene and its audio assets
    static func preloadSceneWithAudio(named sceneName: String, audioFiles: [String], completion: @escaping (Bool) -> Void) {
        preloadScene(named: sceneName) { sceneSuccess in
            if !sceneSuccess {
                completion(false)
                return
            }
            
            preloadAudioFiles(audioFiles) { audioSuccess in
                completion(audioSuccess)
            }
        }
    }
    
    // Preload scene nodes
    private static func preloadScene(named sceneName: String, completion: @escaping (Bool) -> Void) {
        guard let scene = SCNScene(named: sceneName) else {
            print("Scene \(sceneName) not found.")
            completion(false)
            return
        }
        
        let scnView = SCNView()
        scnView.prepare(scene.rootNode.childNodes) { success in
            if success {
                print("Scene \(sceneName) nodes successfully prepared.")
            } else {
                print("Failed to prepare \(sceneName) nodes.")
            }
            completion(success)
        }
    }
    
    // Preload audio assets
    private static func preloadAudioFiles(_ audioFiles: [String], completion: @escaping (Bool) -> Void) {
        var loadedAudioSources = [SCNAudioSource]()
        
        for fileName in audioFiles {
            if let audioSource = SCNAudioSource(fileNamed: fileName) {
                audioSource.shouldStream = false
                audioSource.load()
                loadedAudioSources.append(audioSource)
            } else {
                print("Audio file \(fileName) not found.")
            }
        }
        
        let success = loadedAudioSources.count == audioFiles.count
        if success {
            print("All audio files successfully prepared.")
        } else {
            print("Some audio files could not be loaded.")
        }
        completion(success)
    }
}
