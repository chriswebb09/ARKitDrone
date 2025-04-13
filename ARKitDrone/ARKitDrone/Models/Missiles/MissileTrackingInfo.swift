//
//  MissileTrackingInfo.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

struct MissileTrackingInfo {
    let missile: Missile
    let target: Ship
    let startTime: CFTimeInterval
    let displayLink: CADisplayLink
    var frameCount: Int = 0
    var lastUpdateTime: CFTimeInterval
}
