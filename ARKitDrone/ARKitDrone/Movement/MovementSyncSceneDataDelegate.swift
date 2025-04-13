//
//  MovementSyncSceneDataDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

protocol MovementSyncSceneDataDelegate: AnyObject {
    func hasNetworkDelayStatusChanged(hasNetworkDelay: Bool)
}
