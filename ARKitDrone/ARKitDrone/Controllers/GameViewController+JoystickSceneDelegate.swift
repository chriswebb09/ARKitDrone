//
//  GameViewController+JoystickSceneDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

// MARK: - JoystickSceneDelegate

extension GameViewController: JoystickSceneDelegate {
    
    func update(xValue: Float, stickNum: Int) {
        DispatchQueue.main.async {
            if stickNum == 1 {
                let scaled = (xValue) * 0.0005
                self.sceneView.rotate(value: scaled)
            } else if stickNum == 2 {
                let scaled = (xValue) * 0.05
                self.sceneView.moveSides(value: -scaled)
            }
        }
    }
    
    func update(yValue: Float, stickNum: Int) {
        DispatchQueue.main.async {
            if stickNum == 2 {
                let scaled = (yValue)
                self.sceneView.moveForward(value: (scaled * 0.009))
            } else if stickNum == 1 {
                let scaled = (yValue) * 0.01
                self.sceneView.changeAltitude(value: scaled)
            }
        }
    }
    
    func tapped() {
        guard sceneView.helicopter.missilesArmed else { return }
        DispatchQueue.main.async {
            self.sceneView.fire(game: self.game)
            self.sceneView.addTargetToShip()
        }
    }
}
