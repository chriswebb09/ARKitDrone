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
        let v = GameVelocity(vector: velocity)
        if stickNum == 2 {
            let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .forward)
            sceneView.helicopter.moveForward(value: (velocity.y * 0.95))
            gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
        } else if stickNum == 1 {
            let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .altitude)
            sceneView.helicopter.changeAltitude(value: velocity.y)
            gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
        }
    }
    
    func update(xValue: Float,  velocity: SIMD3<Float>,  angular: Float, stickNum: Int) {
        let v = GameVelocity(vector: velocity)
        var shouldBeSent: MoveData!
        if stickNum == 1 {
            shouldBeSent = MoveData(velocity: v, angular: angular, direction: .side)
            sceneView.helicopter.moveSides(value: velocity.x)
        } else if stickNum == 2 {
            shouldBeSent = MoveData(velocity: v, angular: angular, direction: .rotation)
            sceneView.helicopter.rotate(value: velocity.x)
        }
        gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
    }
    
    func tapped() {
        guard sceneView.helicopter.missilesArmed else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            missileManager.fire(game: game)
            if sceneView.ships.count > sceneView.targetIndex {
                sceneView.targetIndex += 1
                if sceneView.targetIndex < sceneView.ships.count {
                    let canAddTarget = !sceneView.ships[sceneView.targetIndex].isDestroyed && !sceneView.ships[sceneView.targetIndex].targetAdded
                    if canAddTarget {
                        guard sceneView.targetIndex < sceneView.ships.count else { return }
                        let square = TargetNode()
                        sceneView.ships[sceneView.targetIndex].square = square
                        sceneView.scene.rootNode.addChildNode(square)
                        sceneView.ships[sceneView.targetIndex].targetAdded = true
                    }
                }
            }
        }
    }
}
