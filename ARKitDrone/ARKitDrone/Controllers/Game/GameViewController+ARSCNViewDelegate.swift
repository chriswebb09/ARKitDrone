//
//  GameViewController+ARSCNViewDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import os

// DEPRECATED: This ARSCNViewDelegate is no longer used in RealityKit-only mode
// Game loop and ship movement logic has been moved to ARSessionDelegate for RealityKit compatibility
extension GameViewController {
    nonisolated func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
}


