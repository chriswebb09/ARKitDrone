//
//  GameViewController+ARSCNViewDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import os

extension GameViewController: ARSCNViewDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            if self.game.placed {
                self.shipManager.moveShips(placed: self.game.placed)
            }
            self.updateFocusSquare(isObjectVisible: self.game.placed)
        }
        os_signpost(.begin, log: .render_loop, name: .render_loop, signpostID: .render_loop, "Render loop started")
        os_signpost(.begin, log: .render_loop, name: .logic_update, signpostID: .render_loop, "Game logic update started")
        if let gameManager = self.gameManager, gameManager.isInitialized {
            GameTime.updateAtTime(time: time)
            self.gameManager?.update(timeDelta: GameTime.deltaTime)
        }
        os_signpost(.end, log: .render_loop, name: .logic_update, signpostID: .render_loop, "Game logic update finished")
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
}


