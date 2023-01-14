//
//  JoystickSKSceneDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/5/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

protocol JoystickSceneDelegate: AnyObject {
    func update(xValue: Float, stickNum: Int)
    func update(yValue: Float,  stickNum: Int)
    func tapped()
}
