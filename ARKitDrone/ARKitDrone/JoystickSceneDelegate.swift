//
//  JoystickSKSceneDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/5/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

protocol JoystickSceneDelegate: AnyObject {
    func update(velocity: Float)
    func update(altitude: Float)
    func update(rotate: Float)
    func update(sides: Float)
}
