//  SceneManager.swift

import SceneKit

class SceneManager {
    static let shared = SceneManager()
    private var currentScene: SCNScene?
    private var scnView: SCNView?
    private var lightNode: SCNNode?
    
    private init() {}
    
    func configure(with scnView: SCNView) {
        self.scnView = scnView
        initializeLightNode()
    }
    
    // Function to initialize the light node
    private func initializeLightNode() {
        lightNode = SCNNode()
        let light = SCNLight()
        light.type = .omni
        light.intensity = 0
        light.color = UIColor(red: 0.5, green: 0.5, blue: 1.0, alpha: 1.0) // Blueish tint
        lightNode?.light = light
    }
    
    // Func to clear previous scene before load the new one
    private func cleanupCurrentScene() {
        currentScene?.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        currentScene = nil
    }
    
    // Function to load Scene1 and pass the lightNode
    func loadScene1() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene1 = Scene1(lightNode: lightNode)
        scnView?.scene = scene1
        currentScene = scene1
    }
    
    func loadScene2() {
        cleanupCurrentScene()
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene2 = Scene2(lightNode: lightNode)
        scnView?.scene = scene2
        currentScene = scene2
    }
    
    func loadScene4() {
        cleanupCurrentScene()
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        
        let scene4 = Scene4(lightNode: lightNode)
        scnView?.scene = scene4
        currentScene = scene4
    }
    
    func loadScene5and6() {
        cleanupCurrentScene()
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        
        let scene5and6 = Scene5and6(lightNode: lightNode)
        scnView?.scene = scene5and6
    }
    
    func loadScene7() {
        cleanupCurrentScene()
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene7 = Scene7(lightNode: lightNode)
        scnView?.scene = scene7
        currentScene = scene7
    }
    
    func loadScene8() {
        cleanupCurrentScene()
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene8 = Scene8(lightNode: lightNode)
        scnView?.scene = scene8
        currentScene = scene8
    }
    
    func loadScene9() {
        cleanupCurrentScene()
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene9 = Scene9(lightNode: lightNode, scnView: scnView!)
        scnView?.scene = scene9
        currentScene = scene9
    }
    
    func loadScene10() {
        cleanupCurrentScene()
        guard let lightNode = lightNode, let scnView = scnView else {
            print("Error: Light node or SCNView is not initialized.")
            return
        }
        let scene10 = Scene10(lightNode: lightNode, scnView: scnView)
        scnView.scene = scene10
        currentScene = scene10
    }
}
