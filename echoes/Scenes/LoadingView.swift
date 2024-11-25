//  LoadingView.swift

import UIKit

class LoadingView: UIView {
    // MARK: - Subviews
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "echoes_logo")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let logoTextLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        // Apply custom font
        if let customFont = UIFont(name: "MetalMania-Regular", size: 12) {
            label.font = customFont
        } else {
            label.font = UIFont.systemFont(ofSize: 12, weight: .light)
            print("Warning: Failed to load MetalMania-Regular font.")
        }
        
        return label
    }()
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - View Setup
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(1.0)
        
        // Add subviews
        addSubview(logoImageView)
        addSubview(logoTextLabel)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Position the logo image in the bottom right corner
            logoImageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -30),
            logoImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            logoImageView.widthAnchor.constraint(equalToConstant: 60),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Position the text below the logo
            logoTextLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 5),
            logoTextLabel.centerXAnchor.constraint(equalTo: logoImageView.centerXAnchor),
        ])
        
        // Start rotating the logo
        startLogoRotationAnimation()
    }
    
    // MARK: - Animation
    private func startLogoRotationAnimation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 3 // Duration of one full rotation
        rotation.isCumulative = true
        rotation.repeatCount = .infinity
        logoImageView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    // MARK: - Public Methods
    func fadeIn(completion: (() -> Void)? = nil) {
        GameViewController.joystickComponent.hideJoystick()
        
        self.alpha = 0.0
        UIView.animate(withDuration: 1.0, animations: {
            self.alpha = 0.9
        }, completion: { _ in
            completion?()
        })
    }
    
    func fadeOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 1.0, animations: {
            self.alpha = 0.0
        }, completion: { _ in
            completion?()
        })
    }
    
    func stopLoading() {
        fadeOut { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                GameViewController.joystickComponent.showJoystick()
            }
            self?.removeFromSuperview()
        }
    }
}
