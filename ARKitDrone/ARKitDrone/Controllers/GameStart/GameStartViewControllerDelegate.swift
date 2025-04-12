//
//  GameStartViewControllerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import Foundation
import os.log

protocol GameStartViewControllerDelegate: AnyObject {
    func gameStartViewController(_ gameStartViewController: UIViewController, didPressStartSoloGameButton: UIButton)
    func gameStartViewController(_ gameStartViewController: UIViewController, didStart game: NetworkSession)
    func gameStartViewController(_ gameStartViewController: UIViewController, didSelect game: NetworkSession)
}
