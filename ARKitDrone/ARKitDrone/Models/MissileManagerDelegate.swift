//
//  MissileManagerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/19/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

// MARK: - MissileManagerDelegate

@MainActor
protocol MissileManagerDelegate: AnyObject {
    func missileManager(_ manager: MissileManager, didUpdateScore score: Int)
}
