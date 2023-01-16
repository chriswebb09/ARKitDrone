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
        countdownToStart()
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            self.performSegue(withIdentifier: "GoToGame", sender: self)
        }
    }
    
    func countdownToStart() {
        var countdown = 5
        DispatchQueue.global(qos: .default).async {
            for _ in 0...5 {
                if countdown == 5 {
                    sleep(1)
                    countdown -= 1
                    continue
                }
                DispatchQueue.main.async {
                    UIView.transition(with: self.newGameButton,
                                      duration: 0.25,
                                      options: .transitionCrossDissolve,
                                      animations: { [weak self] in
                        self?.newGameButton.titleLabel?.textAlignment = .center
                        self?.newGameButton.titleLabel?.font = self?.newGameButton.titleLabel?.font.withWeight(.heavy)
                        self?.newGameButton.titleLabel?.text = "\(countdown)"
                    }, completion: nil)
                }
                sleep(1)
                countdown -= 1
            }
        }
    }
}
