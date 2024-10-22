// SceneManager.swift

import SceneKit

class SceneManager {
    static let shared = SceneManager()
    private var currentScene: SCNScene?
    private var scnView: SCNView?
    private var lightNode: SCNNode?
    
    private init() {}
    
    func configure(with scnView: SCNView) {
        self.scnView = scnView
        initializeLightNode()  // Initialize the light node here
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
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene2 = Scene2(lightNode: lightNode)
        scnView?.scene = scene2
        currentScene = scene2
    }
    
    func loadScene3() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene3 = Scene3(lightNode: lightNode)
        scnView?.scene = scene3
        currentScene = scene3
    }
    
    func loadScene4() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene4 = Scene4(lightNode: lightNode) 
        scnView?.scene = scene4
        currentScene = scene4
    }
    
    func loadScene5() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene5 = Scene5(lightNode: lightNode)
        scnView?.scene = scene5
        currentScene = scene5
    }
    
    func loadScene6() {
        guard let lightNode = lightNode else {
            print("Error: Light node is not initialized.")
            return
        }
        let scene6 = Scene6(lightNode: lightNode)
        scnView?.scene = scene6
        currentScene = scene6
    }
}
