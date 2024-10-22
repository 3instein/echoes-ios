import UIKit
import GameplayKit

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = scanner.string.startIndex
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

class VirtualJoystickComponent: GKComponent {
    static var shared = VirtualJoystickComponent()
    var joystickView: UIView!
    var joystickKnob: UIView!
    var basePosition: CGPoint = .zero
    var isTouching: Bool = false
    var direction: CGPoint = .zero
    let joystickSize: CGFloat = 140.00 // Reduced from 150.0
    let knobSize: CGFloat = 70.0 // Reduced from 70.0
    var idleTimer: Timer?

    override init() {
        super.init()

        // Set up the joystick base view
        joystickView = UIView(frame: CGRect(x: 50, y: UIScreen.main.bounds.height - joystickSize - 50, width: joystickSize, height: joystickSize))
        joystickView.backgroundColor = UIColor(hex: "2A2DCE")
        joystickView.layer.cornerRadius = joystickSize / 2
        joystickView.alpha = 0.3 // Always visible initially

        // Set up the joystick knob view
        joystickKnob = UIView(frame: CGRect(x: (joystickSize - knobSize) / 2, y: (joystickSize - knobSize) / 2, width: knobSize, height: knobSize))
        joystickKnob.backgroundColor = UIColor(hex: "A0F30C")
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
            resetIdleTimer()
            animateJoystickAlpha(to: 0.5) // Make joystick fully visible
        case .changed:
            let limitedDistance = min(distance, maxDistance)
            let angle = atan2(offset.y, offset.x)
            direction = CGPoint(x: cos(angle), y: sin(angle))
            let xPosition = limitedDistance * cos(angle) + joystickView.bounds.midX - knobSize / 2
            let yPosition = limitedDistance * sin(angle) + joystickView.bounds.midY - knobSize / 2
            joystickKnob.frame.origin = CGPoint(x: xPosition, y: yPosition)
            resetIdleTimer()
        case .ended, .cancelled:
            resetJoystick()
            startIdleTimer()
        default:
            break
        }
    }
    
    func resetJoystick() {
        isTouching = false
        direction = .zero
        joystickKnob.frame.origin = CGPoint(x: (joystickSize - knobSize) / 2, y: (joystickSize - knobSize) / 2)
    }
    
    func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(handleIdleState), userInfo: nil, repeats: false)
    }

    func resetIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    @objc func handleIdleState() {
        if !isTouching {
            animateJoystickAlpha(to: 0.3) // Make joystick more translucent after being idle
        }
    }

    func animateJoystickAlpha(to alpha: CGFloat) {
        UIView.animate(withDuration: 1.0) {
            self.joystickView.alpha = alpha
        }
    }

    // Function to hide the joystick
    func hideJoystick() {
        UIView.animate(withDuration: 0.5) {
            self.joystickView.alpha = 0.0
        } completion: { _ in
            self.joystickView.isHidden = true
        }
    }

    // Function to show the joystick
    func showJoystick() {
        joystickView.isHidden = false
        UIView.animate(withDuration: 0.5) {
            self.joystickView.alpha = 0.3
        }
    }
}
