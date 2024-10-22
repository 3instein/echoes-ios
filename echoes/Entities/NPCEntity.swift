//  NPCEntity.swift

import SceneKit
import GameplayKit

class NPCEntity: GKEntity {
    var npcNode: SCNNode?
    var echolocationComponent: EcholocationComponent?
    
    init(npcNode: SCNNode?, lightNode: SCNNode) {
        super.init()
        
        guard let npcNode = npcNode else {
            print("Warning: NPC node not found")
            return
        }
        self.npcNode = npcNode
        
        // Add the echolocation component to manage echolocation light and sound
        echolocationComponent = EcholocationComponent(lightNode: lightNode)
        addComponent(echolocationComponent!)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func activateEcholocation() {
        echolocationComponent?.activateFlash() // Trigger light flash and sound
    }
}
