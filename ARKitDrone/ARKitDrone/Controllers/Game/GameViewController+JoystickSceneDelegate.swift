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
    
    func update(yValue: Float,  velocity: SIMD3<Float>, angular: Float, stickNum: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let v = GameVelocity(vector: velocity)
            if stickNum == 2 {
                let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .forward)
                sceneView.helicopter.moveForward(value: velocity.y)
                gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
            } else if stickNum == 1 {
                let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .altitude)
                sceneView.helicopter.changeAltitude(value: velocity.y)
                gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
            }
        }
    }
    
    func update(xValue: Float,  velocity: SIMD3<Float>,  angular: Float, stickNum: Int) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let v = GameVelocity(vector: velocity)
            if stickNum == 1 {
                let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .side)
                sceneView.helicopter.moveSides(value: velocity.x)
                gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
            } else if stickNum == 2 {
                let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .rotation)
                sceneView.helicopter.rotate(value: velocity.x)
                gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
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
