import ARKit
import RealityKit
import UIKit

// MARK: - JoystickSceneDelegate

extension GameViewController: JoystickSceneDelegate {
    
    /// Get local player's helicopter from GameManager
    private var localHelicopter: HelicopterObject? {
        return gameManager?.getHelicopter(for: myself)
    }
    
    func update(yValue: Float,  velocity: SIMD3<Float>, angular: Float, stickNum: Int) {
        let v = GameVelocity(vector: velocity)
        if stickNum == 2 {
            let shouldBeSent = MoveData(
                velocity: v,
                angular: angular,
                direction: .forward
            )
            // Move local helicopter through GameManager (unified with multiplayer)
            gameManager?.moveHelicopter(player: myself, movement: shouldBeSent)
            // Send movement to network only if in multiplayer mode
            if let gameManager = gameManager, gameManager.isNetworked {
                gameManager.send(gameAction: .joyStickMoved(shouldBeSent))
            }
        } else if stickNum == 1 {
            let shouldBeSent = MoveData(
                velocity: v,
                angular: angular,
                direction: .altitude
            )
            // Move local helicopter through GameManager (unified with multiplayer)
            gameManager?.moveHelicopter(player: myself, movement: shouldBeSent)
            // Send movement to network only if in multiplayer mode
            if let gameManager = gameManager, gameManager.isNetworked {
                gameManager.send(gameAction: .joyStickMoved(shouldBeSent))
            }
        }
    }
    
    func update(xValue: Float,  velocity: SIMD3<Float>,  angular: Float, stickNum: Int) {
        let v = GameVelocity(vector: velocity)
        var shouldBeSent: MoveData!
        if stickNum == 1 {
            shouldBeSent = MoveData(
                velocity: v,
                angular: angular,
                direction: .side
            )
            // Move local helicopter through GameManager (unified with multiplayer)
            gameManager?.moveHelicopter(player: myself, movement: shouldBeSent)
        } else if stickNum == 2 {
            shouldBeSent = MoveData(
                velocity: v,
                angular: angular,
                direction: .rotation
            )
            // Move local helicopter through GameManager (unified with multiplayer)
            gameManager?.moveHelicopter(player: myself, movement: shouldBeSent)
        }
        // Send movement to network only if in multiplayer mode
        if let gameManager = gameManager, gameManager.isNetworked {
            gameManager.send(gameAction: .joyStickMoved(shouldBeSent))
        }
    }
    
    func tapped() {
        // Check missiles armed through HelicopterObject system
        guard let localHeli = localHelicopter, localHeli.missilesArmed() else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            missileManager?.fire(game: game)
            if realityKitView.ships.count > realityKitView.targetIndex {
                realityKitView.targetIndex += 1
                if realityKitView.targetIndex < realityKitView.ships.count {
                    let canAddTarget = !realityKitView.ships[realityKitView.targetIndex].isDestroyed && !realityKitView.ships[realityKitView.targetIndex].targetAdded
                    if canAddTarget {
                        guard realityKitView.targetIndex < realityKitView.ships.count else { return }
                        let square = ReticleEntity()
                        realityKitView.ships[realityKitView.targetIndex].square = square
                        // Position the reticle at the ship's location
                        square.transform.translation = realityKitView.ships[realityKitView.targetIndex].entity.transform.translation
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
