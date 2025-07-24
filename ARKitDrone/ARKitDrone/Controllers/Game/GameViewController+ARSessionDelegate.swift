//
//  GameViewController+ARSessionDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/14/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import os

extension GameViewController: ARSessionDelegate {
    
    private static var lastShipUpdateTime: TimeInterval = 0
    private static let shipUpdateInterval: TimeInterval = 1.0/15.0  // 15 FPS instead of 60
    
    nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            // Only update focus square if game is not placed
            if !self.game.placed {
                self.updateFocusSquare(isObjectVisible: false)
            }
            // Throttle ship movement updates to 15 FPS
            let currentTime = CACurrentMediaTime()
            if currentTime - Self.lastShipUpdateTime > Self.shipUpdateInterval {
                Self.lastShipUpdateTime = currentTime
                // Update ship movements if game is placed
                if self.game.placed {
                    Task { @MainActor in
                        self.shipManager?.moveShips(placed: self.game.placed)
                    }
                }
            }
        }
        // Game logic updates
        os_signpost(
            .begin,
            log: .render_loop,
            name: .render_loop,
            signpostID: .render_loop,
            "Render loop started"
        )
        os_signpost(
            .begin,
            log: .render_loop,
            name: .logic_update,
            signpostID: .render_loop,
            "Game logic update started"
        )
        
        Task { @MainActor in
            if let gameManager = self.gameManager {
                GameTime.updateAtTime(time: frame.timestamp)
                self.gameManager?.update(timeDelta: GameTime.deltaTime)
            }
        }
        
        os_signpost(
            .end,
            log: .render_loop,
            name: .logic_update,
            signpostID: .render_loop,
            "Game logic update finished"
        )
    }
    
    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle anchor additions if needed
        for anchor in anchors {
            os_log(
                .info,
                "Added anchor: %@",
                anchor.description
            )
        }
    }
    
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        // Handle anchor updates if needed
    }
    
    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        // Handle anchor removals if needed
        for anchor in anchors {
            os_log(
                .info,
                "Removed anchor: %@",
                anchor.description
            )
        }
    }
}
