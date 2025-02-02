//
//  Tank.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/31/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit
import simd

protocol Tank {
    func rotateTurret(rotation: Float)
    func moveTurretVertical(value: Float)
    func fire()
    func move(direction: Float)
    func rotate(angle: Float)
}
