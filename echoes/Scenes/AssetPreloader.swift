//  AssetPreloader.swift

import SceneKit

class AssetPreloader {
    // Preload Scene2
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
    
    // Preload Scene4
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
    
    // Preload Scenes5and6
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
    
    // Preload Scene7
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
    
    // Preload Scene8
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
    
    // Preload Scene9
    static func preloadScene9(completion: @escaping (Bool) -> Void) {
        let sceneName = "scene9.scn"
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
    
    // Preload scene nodes, geometries, materials, textures, and animations
    private static func preloadScene(named sceneName: String, completion: @escaping (Bool) -> Void) {
        guard let scene = SCNScene(named: sceneName) else {
            print("Scene \(sceneName) not found.")
            completion(false)
            return
        }
        
        // Preload all child nodes and their properties
        let scnView = SCNView()
        scnView.prepare(scene.rootNode.childNodes) { success in
            if success {
                print("Scene \(sceneName) nodes successfully prepared.")
                scene.rootNode.enumerateChildNodes { node, _ in
                    preloadNodeProperties(node)
                }
            } else {
                print("Failed to prepare \(sceneName) nodes.")
            }
            completion(success)
        }
    }
    
    // Preload node properties: geometry, materials, textures, animations
    private static func preloadNodeProperties(_ node: SCNNode) {
        // Access geometry
        if let geometry = node.geometry {
            _ = geometry.materials // Access materials
            geometry.materials.forEach { material in
                if let texture = material.diffuse.contents as? UIImage {
                    _ = texture.cgImage // Force texture loading
                }
            }
        }
        
        // Access animations
        node.animationKeys.forEach { key in
            if let animationPlayer = node.animationPlayer(forKey: key) {
                node.addAnimationPlayer(animationPlayer, forKey: key)
            }
        }
        
        // Preload child nodes recursively
        node.childNodes.forEach { preloadNodeProperties($0) }
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
