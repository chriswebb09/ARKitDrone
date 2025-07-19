import ARKit
import RealityKit
import UIKit

// MARK: - JoystickSceneDelegate

extension GameViewController: JoystickSceneDelegate {
    
    func update(yValue: Float,  velocity: SIMD3<Float>, angular: Float, stickNum: Int) {
        let v = GameVelocity(vector: velocity)
        if stickNum == 2 {
            let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .forward)
            realityKitView.helicopter.moveForward(value: (velocity.y * 0.95))
            gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
        } else if stickNum == 1 {
            let shouldBeSent = MoveData(velocity: v, angular: angular, direction: .altitude)
            realityKitView.helicopter.changeAltitude(value: velocity.y)
            gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
        }
    }
    
    func update(xValue: Float,  velocity: SIMD3<Float>,  angular: Float, stickNum: Int) {
        let v = GameVelocity(vector: velocity)
        var shouldBeSent: MoveData!
        if stickNum == 1 {
            shouldBeSent = MoveData(velocity: v, angular: angular, direction: .side)
            realityKitView.helicopter.moveSides(value: velocity.x)
        } else if stickNum == 2 {
            shouldBeSent = MoveData(velocity: v, angular: angular, direction: .rotation)
            realityKitView.helicopter.rotate(yaw: velocity.x)
        }
        gameManager?.send(gameAction: .joyStickMoved(shouldBeSent))
    }
    
    func tapped() {
        guard realityKitView.helicopter.missilesArmed else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            missileManager?.fire(game: game)
            if realityKitView.ships.count > realityKitView.targetIndex {
                realityKitView.targetIndex += 1
                if realityKitView.targetIndex < realityKitView.ships.count {
                    let canAddTarget = !realityKitView.ships[realityKitView.targetIndex].isDestroyed && !realityKitView.ships[realityKitView.targetIndex].targetAdded
                    if canAddTarget {
                        guard realityKitView.targetIndex < realityKitView.ships.count else { return }
                        let square = TargetNode()
                        realityKitView.ships[realityKitView.targetIndex].square = square
                        
                        // Add to ship's anchor
                        if let parent = realityKitView.ships[realityKitView.targetIndex].entity.parent {
                            parent.addChild(square)
                        }
                        
                        realityKitView.ships[realityKitView.targetIndex].targetAdded = true
                    }
                }
            }
        }
    }
}
