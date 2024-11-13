//  VirtualJoystickComponent.swift

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
    var isEnabled: Bool = true
    static var shared = VirtualJoystickComponent()
    var joystickView: UIView!
    var joystickKnob: UIView!
    var instructionLabel: UILabel!
    var cameraInstructionLabel: UILabel!
    var basePosition: CGPoint = .zero
    var isTouching: Bool = false
    var direction: CGPoint = .zero
    let joystickSize: CGFloat = 140.0
    let knobSize: CGFloat = 70.0
    var idleTimer: Timer?
    private var hasShownCameraInstruction = false
    
    override init() {
        super.init()
        
        // Set up the joystick base view
        joystickView = UIView(frame: CGRect(x: 50, y: UIScreen.main.bounds.height - joystickSize - 50, width: joystickSize, height: joystickSize))
        joystickView.backgroundColor = UIColor(hex: "3C3EBB")
        joystickView.layer.cornerRadius = joystickSize / 2
        joystickView.alpha = 0.3 // Default visibility
        
        // Set up the joystick knob view
        joystickKnob = UIView(frame: CGRect(x: (joystickSize - knobSize) / 2, y: (joystickSize - knobSize) / 2, width: knobSize, height: knobSize))
        joystickKnob.backgroundColor = UIColor(hex: "4B4EE8")
        joystickKnob.layer.cornerRadius = knobSize / 2
        joystickView.addSubview(joystickKnob)
        
        // Set up the joystick instruction label
        instructionLabel = UILabel()
        instructionLabel.text = "Drag to move"
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = UIColor.white
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        instructionLabel.layer.cornerRadius = 10
        instructionLabel.clipsToBounds = true
        instructionLabel.alpha = 0.0
        applyCustomFont(to: instructionLabel, fontSize: 14)
        
        // Set up the camera rotation instruction label in the center of the screen
        cameraInstructionLabel = UILabel()
        cameraInstructionLabel.text = "Rotate the camera to look around"
        cameraInstructionLabel.textAlignment = .center
        cameraInstructionLabel.textColor = UIColor.white
        cameraInstructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        cameraInstructionLabel.layer.cornerRadius = 10
        cameraInstructionLabel.clipsToBounds = true
        cameraInstructionLabel.alpha = 0.0
        applyCustomFont(to: cameraInstructionLabel, fontSize: 14)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Apply the custom font to a label
    private func applyCustomFont(to label: UILabel, fontSize: CGFloat) {
        if let customFont = UIFont(name: "SpecialElite-Regular", size: fontSize) {
            label.font = customFont
        } else {
            print("Failed to load SpecialElite-Regular font.")
        }
    }
    
    func attachToView(_ view: UIView) {
        view.addSubview(joystickView)
        view.addSubview(instructionLabel)
        view.addSubview(cameraInstructionLabel)
        
        // Position the move instruction label above the joystick
        instructionLabel.frame = CGRect(x: joystickView.frame.midX - 55, y: joystickView.frame.minY - 40, width: 110, height: 25)
        
        // Position the camera instruction label above the center of the screen
        let offsetFromTop: CGFloat = 170
        cameraInstructionLabel.frame = CGRect(
            x: (view.frame.width - 250) / 2,
            y: view.frame.height / 2 - offsetFromTop,
            width: 255,
            height: 25
        )
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        joystickView.addGestureRecognizer(panGestureRecognizer)
    }
    
    // Show the joystick tutorial with a delay
    func showJoystickTutorial() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showInstructionLabel()
        }
    }
    
    private func showInstructionLabel() {
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 1.0
        }
    }
    
    private func hideInstructionLabelWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(withDuration: 0.5) {
                self.instructionLabel.alpha = 0.0
            }
        }
    }
    
    private func showCameraInstructionLabel() {
        guard !hasShownCameraInstruction else { return }  // Show only if not displayed before
        hasShownCameraInstruction = true
        UIView.animate(withDuration: 0.5) {
            self.cameraInstructionLabel.alpha = 1.0
        }
    }
    
    private func hideCameraInstructionLabelWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            UIView.animate(withDuration: 0.5) {
                self.cameraInstructionLabel.alpha = 0.0
            }
        }
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
            animateJoystickAlpha(to: 0.5)
            hideInstructionLabelWithDelay()
            showCameraInstructionLabel()
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
            hideCameraInstructionLabelWithDelay()
        default:
            break
        }
    }
    
    func resetJoystick() {
        isTouching = false
        direction = .zero
        DispatchQueue.main.async {
            self.joystickKnob.frame.origin = CGPoint(x: (self.joystickSize - self.knobSize) / 2, y: (self.joystickSize - self.knobSize) / 2)
        }
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
        // Make joystick more translucent after being idle
        if !isTouching {
            animateJoystickAlpha(to: 0.3)
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
