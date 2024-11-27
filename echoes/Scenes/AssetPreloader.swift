//  AssetPreloader.swift

import SceneKit

class AssetPreloader {
    // MARK: - Public Methods
    static func preloadScene2(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene2.scn"
        let audioFiles = [
            "doorOpen.MP3",
            "doorClose.MP3",
            "s3-grandma.mp3",
            "s3-andra.mp3",
            "wind.wav",
            "crow.wav",
            "outsideRain.wav",
            "grassFootsteps.wav",
            "woodFootsteps.wav"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScene4(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene4ely.scn"
        let audioFiles = [
            "woodenFloor.wav",
            "clockTicking.wav",
            "muffledRain.wav",
            "s4-andra.wav",
            "s4-grandma1.wav",
            "s4-grandma2.wav"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScenes5and6(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene5and6ely.scn"
        let audioFiles = [
            "woodenFloor.wav",
            "clockTicking.wav",
            "muffledRain.wav",
            "s5-grandma.wav",
            "s5-andra.wav",
            "fallingCup.mp3",
            "puzzleFinish.wav",
            "doorOpen.MP3",
            "doorClose.MP3"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScene7(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene7.scn"
        let audioFiles = [
            "muffledRain.wav",
            "MusicBox.MP3",
            "jumpascareGrandma.MP3",
            "s7-grandma.MP3",
            "SwanLakeRingtone.MP3"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScene8(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene8ely.scn"
        let audioFiles = [
            "muffledRain.wav",
            "s8-andra1.mp3",
            "pipeNecklace.mp3",
            "s8-andra2.mp3",
            "pipeAfterOut.wav",
            "fallingNecklace.mp3",
            "s8-andra3.mp3",
            "s8-andra4.mp3",
            "jumpscare1.wav",
            "doll2.wav",
            "whisperJumpscare.mp3",
            "waterNecklacePipe.mp3",
            "door_close.mp3"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScene9(completion: @escaping (Bool) -> Void) {
        let sceneName = "Scene9.scn"
        let audioFiles = [
            "woodenFloor.wav",
            "clockTicking.wav",
            "outsideRain.wav",
            "step.mp3",
            "ritualBackground.wav",
            "s9-kirana1.wav",
            "s9-kirana2.wav",
            "s9-andra.wav",
            "s9-reza2.wav",
            "jumpscare.wav"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }
    
    static func preloadScene10(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene10.scn"
        let audioFiles = [
            "ritualSuccess.wav",
            "doorCreaking.mp3",
            "finalDialogue1.wav",
            "finalDialogue2.wav",
            "backgroundAmbience.mp3"
        ]
        preloadSceneWithAudio(named: sceneName, audioFiles: audioFiles, completion: completion)
    }

    
    // MARK: - Core Preloading Logic
    static func preloadSceneWithAudio(named sceneName: String, audioFiles: [String], completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            preloadScene(named: sceneName) { sceneSuccess in
                if !sceneSuccess {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                    return
                }
                
                preloadAudioFiles(audioFiles) { audioSuccess in
                    DispatchQueue.main.async {
                        completion(audioSuccess)
                    }
                }
            }
        }
    }
    
    // MARK: - Scene Preloading
    private static func preloadScene(named sceneName: String, completion: @escaping (Bool) -> Void) {
        guard let scene = SCNScene(named: sceneName) else {
            print("Scene named '\(sceneName)' not found.")
            completion(false)
            return
        }
        
        let scnView = SCNView()
        let childNodes = scene.rootNode.childNodes
        
        var success = true
        for node in childNodes {
            let nodePrepared = scnView.prepare(node, shouldAbortBlock: nil)
            if !nodePrepared {
                print("Failed to prepare node \(node.name ?? "Unnamed Node")")
                success = false
            } else {
                preloadNodeProperties(node)
            }
        }
        
        if success {
            print("Scene \(sceneName) nodes successfully prepared.")
        } else {
            print("Some nodes in \(sceneName) failed to prepare.")
        }
        completion(success)
    }
    
    // MARK: - Node Property Preloading
    private static func preloadNodeProperties(_ node: SCNNode) {
        // Preload geometry and materials
        if let geometry = node.geometry {
            geometry.materials.forEach { material in
                _ = material.diffuse.contents as? UIImage
                _ = material.normal.contents as? UIImage
                _ = material.ambient.contents as? UIImage
            }
        }
        
        // Preload animations
        node.animationKeys.forEach { key in
            if let animationPlayer = node.animationPlayer(forKey: key) {
                animationPlayer.stop() // Ensure it's initialized
            }
        }
        
        // Preload child nodes recursively
        node.childNodes.forEach { preloadNodeProperties($0) }
    }
    
    // MARK: - Audio Preloading
    private static func preloadAudioFiles(_ audioFiles: [String], completion: @escaping (Bool) -> Void) {
        var loadedAudioSources = [SCNAudioSource]()
        
        for fileName in audioFiles {
            if let audioSource = SCNAudioSource(fileNamed: fileName) {
                audioSource.shouldStream = fileName.hasSuffix(".mp3") // Stream large files
                audioSource.loops = fileName.contains("loop") // Loop ambient sounds
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
