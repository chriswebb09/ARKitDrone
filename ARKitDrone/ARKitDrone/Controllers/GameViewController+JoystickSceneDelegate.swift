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
                self.missileManager.fire(game: self.game)
                //(at: self.sceneView.ships[self.sceneView.targetIndex])
                if self.sceneView.ships.count > self.sceneView.targetIndex {
                    self.sceneView.targetIndex += 1
                    if self.sceneView.targetIndex < self.sceneView.ships.count {
                        if !self.sceneView.ships[self.sceneView.targetIndex].isDestroyed && !self.sceneView.ships[self.sceneView.targetIndex].targetAdded {
                            DispatchQueue.main.async {
                                guard self.sceneView.targetIndex < self.sceneView.ships.count else { return }
                                let square = TargetNode()
                                self.sceneView.ships[self.sceneView.targetIndex].square = square
                                self.sceneView.scene.rootNode.addChildNode(square)
                                self.sceneView.ships[self.sceneView.targetIndex].targetAdded = true
                            }
                        }
                    }
                }
            }
        }
    
//    func tapped() {
//        guard sceneView.helicopter.missilesArmed else { return }
//        DispatchQueue.main.async {
//
////            self.missileManager.fireMissile(at: self.sceneView.ships[self.sceneView.targetIndex])
////            self.sceneView.fire(game: self.game)
//            self.sceneView.addTargetToShip()
//        }
//    }
}
