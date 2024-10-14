// SceneManager.swift

import SceneKit
import UIKit

class SceneManager {
    static let shared = SceneManager()
    private var currentScene: SCNScene?
    private var scnView: SCNView?

    private init() {}

    func configure(with scnView: SCNView) {
        self.scnView = scnView
    }

    func loadScene(named sceneName: String) {
        guard let scnView = scnView else {
            print("Error: SCNView is not configured. Call configure(with:) first.")
            return
        }

        guard let newScene = SCNScene(named: sceneName) else {
            print("Error: Scene named \(sceneName) not found.")
            return
        }

        // Assign the new scene to the SCNView
        scnView.scene = newScene
        currentScene = newScene
    }

    func loadScene1() {
        let scene1 = Scene1()
        scnView?.scene = scene1
        currentScene = scene1
    }
}
