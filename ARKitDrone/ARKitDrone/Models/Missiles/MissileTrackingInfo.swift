//
//  MissileTrackingInfo.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/19/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

// MARK: - MissileTrackingInfo

struct MissileTrackingInfo {
    let missile: Missile
    let target: Ship
    let startTime: TimeInterval
    let duration: TimeInterval
    let displayLink: CADisplayLink
    var lastUpdateTime: TimeInterval
    var frameCount: Int = 0
}

