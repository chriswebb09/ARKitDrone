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
            newGameButton.layer.cornerRadius = 12
            newGameButton.layer.borderWidth = 2
            newGameButton.layer.borderColor = UIColor.blue.cgColor
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
