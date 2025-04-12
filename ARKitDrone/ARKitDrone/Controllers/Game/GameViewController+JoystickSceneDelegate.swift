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
    
    func update(yValue xValue: Float,  velocity: SIMD3<Float>, angular: Float, stickNum: Int) {
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
    
    func update(xValue yValue: Float,  velocity: SIMD3<Float>,  angular: Float, stickNum: Int) {
        DispatchQueue.main.async {
            if stickNum == 2 {
                let scaled = (yValue) * 0.009
                
                let velocity = SIMD3<Float>(Float(velocity.x), Float(velocity.y), Float(0))
   
                let v = GameVelocity(vector: velocity)
//                let angular = Float(data.angular)
                let shouldBeSent = MoveData(velocity: v, angular: angular)
                self.sceneView.moveForward(value: shouldBeSent.velocity.vector.y)
                
                DispatchQueue.main.async {
                    self.gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
                }
                
                
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
}
