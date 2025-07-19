//
//  MenuViewController.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/15/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let goToGameSegue = "GoToGame"
        static let count = 0
    }
    
    // MARK: - Neumorphic Properties
    
    let darkShadow = CALayer()
    let lightShadow = CALayer()
    
    // MARK: - Private Properties
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        //        label.text = "ARKit Drone"
        label.font = UIFont.systemFont(ofSize: 36, weight: .bold)
        label.textColor = UIColor.darkGray
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var newGameButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("New Game", for: .normal)
        button.backgroundColor = .offWhite
        button.layer.cornerRadius = 20
        // Dark shadow (bottom-right)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        button.layer.shadowOpacity = 0.15
        button.layer.shadowRadius = 10
        button.setTitleColor(.darkGray, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.addTarget(self, action: #selector(newGameButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.offWhite
        setupUI()
    }
    
    
    private func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(newGameButton)
        NSLayoutConstraint.activate([
            // Title label
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            // New game button
            newGameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newGameButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            newGameButton.widthAnchor.constraint(equalToConstant: 200),
            newGameButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    // MARK: - Button Actions
    
    @objc private func newGameButtonTapped() {
        DispatchQueue.main.async {
            DeviceOrientation.shared.set(orientation: .landscapeRight)
            self.countdownToStart(count: 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [self] in
                self.navigateToGame()
            }
        }
    }
    
    private func navigateToGame() {
        let gameViewController = GameViewController()
        // Present the game view controller first (this becomes the main controller)
        gameViewController.modalPresentationStyle = .fullScreen
        present(gameViewController, animated: true) {
            // The GameViewController will handle showing its GameStartViewController
            // with the proper delegate relationship already set up in viewDidLoad
        }
    }
    
    // MARK: - Private Methods
    
    private func countdownToStart(count: Int) {
        var countdown = count
        // Disable button during countdown
        newGameButton.isEnabled = false
        // Set initial countdown display
        newGameButton.setTitle("\(countdown)", for: .normal)
        newGameButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        Task {
            for _ in 1...count {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                countdown -= 1
                await MainActor.run {
                    UIView.transition(with: self.newGameButton, duration: 0.3, options: .transitionCrossDissolve, animations: {
                        let title = countdown > 0 ? "\(countdown)" : "GO!"
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        self.newGameButton.setTitle(title, for: .normal)
                        self.newGameButton.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
                        
                    }, completion: { _ in
                        if countdown == 0 {
                            // Reset button after countdown
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.newGameButton.setTitle("New Game", for: .normal)
                                self.newGameButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
                                self.newGameButton.isEnabled = true
                            }
                        }
                    })
                }
            }
        }
    }
}
