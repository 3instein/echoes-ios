//  SceneManager.swift

import SceneKit

class SceneManager {
    // MARK: - Properties & Initialization
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
    
    // MARK: - Clean Current Scene Mechanism
    func cleanupCurrentScene() {
        guard let currentScene = currentScene else { return }
        
        print("Cleaning up scene: \(currentScene)")
        
        currentScene.rootNode.childNodes.forEach { node in
            // Clear materials
            node.geometry?.materials.forEach { material in
                material.diffuse.contents = nil
                material.normal.contents = nil
                material.ambient.contents = nil
                material.specular.contents = nil
            }
            // Remove animations and actions
            node.removeAllAnimations()
            node.removeAllActions()
            node.childNodes.forEach { $0.removeFromParentNode() }
        }
        
        // Ensure all child nodes are removed from the rootNode
        while !currentScene.rootNode.childNodes.isEmpty {
            currentScene.rootNode.childNodes.first?.removeFromParentNode()
        }
        
        currentScene.rootNode.removeAllAnimations()
        currentScene.rootNode.removeAllActions()
        
        SCNTransaction.flush()  // Force completion of rendering tasks
        scnView?.scene = nil  // Unlink the scene from the SCNView
        self.currentScene = nil
        
        print("Scene cleanup complete.")
    }
    
    // MARK: - Scene Loader
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
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        
        let scene5and6 = Scene5and6(lightNode: lightNode)
        scnView?.scene = scene5and6
    }
    
    func loadScene7() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene7 = Scene7(lightNode: lightNode)
        scnView?.scene = scene7
        currentScene = scene7
    }
    
    func loadScene8() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene8 = Scene8(lightNode: lightNode)
        scnView?.scene = scene8
        currentScene = scene8
    }
    
    func loadScene9() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene9 = Scene9(lightNode: lightNode, scnView: scnView!)
        scnView?.scene = scene9
        currentScene = scene9
    }
    
    func loadScene10() {
        guard let lightNode = lightNode, let scnView = scnView else {
            print("Error: Light node or SCNView is not initialized.")
            return
        }
        let scene10 = Scene10(lightNode: lightNode, scnView: scnView)
        scnView.scene = scene10
        currentScene = scene10
    }
    
    func loadScene11() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene11 = Scene11(lightNode: lightNode)
        scnView?.scene = scene11
        currentScene = scene11
    }
    
    func loadScene12() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene12 = Scene12(lightNode: lightNode)
        scnView?.scene = scene12
        currentScene = scene12
    }
}
