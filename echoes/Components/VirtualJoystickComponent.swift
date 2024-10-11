import UIKit
import GameplayKit

class VirtualJoystickComponent: GKComponent {
    var joystickView: UIView!
    var joystickKnob: UIView!
    var basePosition: CGPoint = .zero
    var isTouching: Bool = false
    var direction: CGPoint = .zero
    let joystickSize: CGFloat = 150.0
    let knobSize: CGFloat = 70.0

    override init() {
        super.init()

        // Set up the joystick base view
        joystickView = UIView(frame: CGRect(x: 50, y: UIScreen.main.bounds.height - joystickSize - 50, width: joystickSize, height: joystickSize))
        joystickView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        joystickView.layer.cornerRadius = joystickSize / 2
        joystickView.alpha = 1.0 // Always visible

        // Set up the joystick knob view
        joystickKnob = UIView(frame: CGRect(x: (joystickSize - knobSize) / 2, y: (joystickSize - knobSize) / 2, width: knobSize, height: knobSize))
        joystickKnob.backgroundColor = UIColor.systemBlue
        joystickKnob.layer.cornerRadius = knobSize / 2
        joystickView.addSubview(joystickKnob)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func attachToView(_ view: UIView) {
        view.addSubview(joystickView)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        joystickView.addGestureRecognizer(panGestureRecognizer)
    }

    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: joystickView)
        let offset = CGPoint(x: location.x - joystickView.bounds.midX, y: location.y - joystickView.bounds.midY)
        let distance = sqrt(offset.x * offset.x + offset.y * offset.y)
        let maxDistance = joystickSize / 2

        switch gesture.state {
        case .began:
            isTouching = true
        case .changed:
            let limitedDistance = min(distance, maxDistance)
            let angle = atan2(offset.y, offset.x)
            direction = CGPoint(x: cos(angle), y: sin(angle))
            let xPosition = limitedDistance * cos(angle) + joystickView.bounds.midX - knobSize / 2
            let yPosition = limitedDistance * sin(angle) + joystickView.bounds.midY - knobSize / 2
            joystickKnob.frame.origin = CGPoint(x: xPosition, y: yPosition)
        case .ended, .cancelled:
            isTouching = false
            direction = .zero
            joystickKnob.frame.origin = CGPoint(x: (joystickSize - knobSize) / 2, y: (joystickSize - knobSize) / 2)
        default:
            break
        }
    }
}
