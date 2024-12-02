// CameraComponent.swift

import SceneKit
import UIKit

class CameraComponent {
    private var cameraNode: SCNNode
    private var playerNode: SCNNode?
    private var isCameraLocked: Bool = false
    
    init(cameraNode: SCNNode, playerNode: SCNNode?) {
        self.cameraNode = cameraNode
        self.playerNode = playerNode
    }
    
    func setupGestureRecognizers(for view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    func lockCamera() {
        isCameraLocked = true
    }
    
    func unlockCamera() {
        isCameraLocked = false
    }
    
    func resetCameraOrientation(to playerNode: SCNNode) {
        // Align the camera's orientation with the player's current orientation
        cameraNode.eulerAngles = SCNVector3(
            playerNode.eulerAngles.x,
            playerNode.eulerAngles.y,
            playerNode.eulerAngles.z
        )
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        guard !isCameraLocked else { return } // Prevent gesture handling if the camera is locked
        
        let translation = gesture.translation(in: gesture.view)
        let sensitivity: Float = 0.005 // Adjust sensitivity as needed
        
        switch gesture.state {
        case .changed:
            // Calculate the rotation deltas
            let deltaX = Float(translation.x) * sensitivity
            let deltaY = Float(translation.y) * sensitivity
            
            // Update camera rotation
            var currentOrientation = cameraNode.eulerAngles
            
            // Limit vertical rotation (up/down) to a reasonable range, e.g., -90 to 90 degrees
            currentOrientation.x = max(min(currentOrientation.x - deltaY, .pi / 4), -.pi / 4)
            
            // Limit horizontal rotation (left/right) if needed
            currentOrientation.y += deltaX
            
            // Apply the clamped rotations to the camera node
            cameraNode.eulerAngles = currentOrientation
            
            // Update player rotation to match camera's horizontal rotation (Y-axis only)
            if let playerNode = playerNode {
                playerNode.eulerAngles.y = currentOrientation.y
            }
            
            // Reset translation to avoid compounding the movement excessively
            gesture.setTranslation(.zero, in: gesture.view)
        default:
            break
        }
    }
}
