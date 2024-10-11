// CameraComponent.swift

import SceneKit
import UIKit

class CameraComponent {
    private var cameraNode: SCNNode
    private var lastPanLocation: CGPoint?
    
    init(cameraNode: SCNNode) {
        self.cameraNode = cameraNode
        setupGestureRecognizers()
    }
    
    private func setupGestureRecognizers() {
        guard let view = UIApplication.shared.windows.first?.rootViewController?.view else {
            return
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)
        
        switch gesture.state {
        case .began:
            lastPanLocation = translation
        case .changed:
            guard let lastLocation = lastPanLocation else { return }
            
            let deltaX = Float(lastLocation.x - translation.x) * 0.005
            let deltaY = Float(lastLocation.y - translation.y) * 0.005
            
            let currentOrientation = cameraNode.eulerAngles
            cameraNode.eulerAngles = SCNVector3(
                currentOrientation.x - deltaY,
                currentOrientation.y - deltaX,
                currentOrientation.z
            )
            
            lastPanLocation = translation
        case .ended, .cancelled:
            lastPanLocation = nil
        default:
            break
        }
    }
}
