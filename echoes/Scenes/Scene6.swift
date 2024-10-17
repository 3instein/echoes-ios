//
//  Scene4.swift
//  echoes
//
//  Created by Pelangi Masita Wati on 15/10/24.
//

// GameScene.swift

import SceneKit
import UIKit

class Scene6: SCNScene {
    var playerEntity: PlayerEntity!
    var cameraNode: SCNNode!
    var cameraComponent: CameraComponent!
    var lightNode: SCNNode!

    override init() {
        super.init()
        // Add any additional setup for the scene here
    }
    
    func setupGestureRecognizers(for view: UIView) {
        cameraComponent.setupGestureRecognizers(for: view)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // Add any additional setup for the scene here
    }
}
