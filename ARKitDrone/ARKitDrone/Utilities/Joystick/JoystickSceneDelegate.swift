//
//  JoystickSKSceneDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/5/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

@MainActor
protocol JoystickSceneDelegate: AnyObject {
    func update(xValue: Float, velocity: SIMD3<Float>, angular: Float, stickNum: Int)
    func update(yValue: Float, velocity: SIMD3<Float>, angular: Float, stickNum: Int)
    func tapped()
}
