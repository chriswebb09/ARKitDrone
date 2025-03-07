//
//  GameViewController+ARSCNViewDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        shipManager.moveShips(placed: game.placed)
        if !game.placed && isLoaded {
            DispatchQueue.main.async {
                self.updateFocusSquare(isObjectVisible: false)
            }
        }
    }
}
