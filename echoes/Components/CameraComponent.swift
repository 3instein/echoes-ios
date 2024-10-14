// CameraComponent.swift

import SceneKit
import UIKit

class CameraComponent {
    private var cameraNode: SCNNode

    init(cameraNode: SCNNode) {
        self.cameraNode = cameraNode
    }

    func setupGestureRecognizers(for view: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }

    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)

        switch gesture.state {
        case .began:
            // Nothing specific needed on gesture begin.
            break
        case .changed:
            let deltaX = Float(translation.x) * 0.005
            let deltaY = Float(translation.y) * 0.005

            let currentOrientation = cameraNode.eulerAngles
            cameraNode.eulerAngles = SCNVector3(
                currentOrientation.x - deltaY,
                currentOrientation.y - deltaX,
                currentOrientation.z
            )

            // Reset translation to avoid compounding the movement excessively
            gesture.setTranslation(.zero, in: gesture.view)
        case .ended, .cancelled:
            // Gesture ended or cancelled, nothing to reset here.
            break
        default:
            break
        }
    }
}
