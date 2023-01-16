//
//  MenuViewController.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/15/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    @IBOutlet weak var newGameButton: UIButton! {
        didSet {
            newGameButton.setshadow()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.offWhite
    }
    
    @IBAction func newGameTapped(_ sender: Any) {
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        countdownToStart(count: 6)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [self] in
            newGameButton.isHidden = true
            performSegue(withIdentifier: "GoToGame", sender: self)
        }
    }
    
    func countdownToStart(count: Int) {
        var countdown = count
        newGameButton.titleLabel?.textAlignment = .center
        newGameButton.titleLabel?.font = newGameButton.titleLabel?.font.withWeight(.heavy)
        newGameButton.titleLabel?.text = "\(countdown)"
        DispatchQueue.global(qos: .default).async {
            for _ in 0...5 {
                if countdown == 6 {
                    sleep(1)
                    countdown -= 1
                    continue
                }
                DispatchQueue.main.async {
                    UIView.transition(with: self.newGameButton, duration: 0.25, options: .transitionCrossDissolve, animations: { [self] in
                        newGameButton.titleLabel?.textAlignment = .center
                        newGameButton.titleLabel?.font = newGameButton.titleLabel?.font.withWeight(.heavy)
                        newGameButton.titleLabel?.text = "\(countdown)"
                    }, completion: nil)
                }
                sleep(1)
                countdown -= 1
            }
        }
    }
}
