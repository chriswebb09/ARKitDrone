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
    
    // MARK: - Private Properties
    
    @IBOutlet private weak var newGameButton: UIButton! {
        didSet {
            newGameButton.setshadow()
        }
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.offWhite
    }
    
    // MARK: - Button Actions
    
    @IBAction func newGameTapped(_ sender: Any) {
        DispatchQueue.main.async {
            DeviceOrientation.shared.set(orientation: .landscapeRight)
            self.newGameButton.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
                self.performSegue(withIdentifier: LocalConstants.goToGameSegue, sender: self)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func countdownToStart(count: Int) {
        var countdown = count
        newGameButton.titleLabel?.textAlignment = .center
        newGameButton.titleLabel?.font = newGameButton.titleLabel?.font.withWeight(.heavy)
        newGameButton.titleLabel?.text = "\(countdown)"
        DispatchQueue.global(qos: .default).async {
            for _ in 1...LocalConstants.count {
                if countdown == LocalConstants.count {
                    sleep(1)
                    countdown -= 1
                    continue
                }
                DispatchQueue.main.async {
                    UIView.transition(with: self.newGameButton, duration: 0.1, options: .transitionCrossDissolve, animations: { [self] in
                        newGameButton.titleLabel?.textAlignment = .center
                        newGameButton.titleLabel?.font = newGameButton.titleLabel?.font.withWeight(.heavy)
                        newGameButton.titleLabel?.text = "\(countdown)"
                    }, completion: nil)
                }
            }
        }
    }
}
