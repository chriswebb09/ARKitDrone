//
//  MissileManager.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import simd
import UIKit

// MARK: - MissileManager

class MissileManager {
    
    // MARK: - Properties
    
    var activeMissileTrackers: [String: MissileTrackingInfo] = [:]
    var game: Game
    var sceneView: GameSceneView
    let missileSpeed: Float = 5
    weak var delegate: MissileManagerDelegate?
    
    // MARK: - Init
    
    init(game: Game, sceneView: GameSceneView) {
        self.game = game
        self.sceneView = sceneView
    }
    
    // MARK: - Fire Missile
    
    @MainActor
    func fire(game: Game) {
        guard !sceneView.helicopter.missiles.isEmpty, !game.scoreUpdated else {
            print("❌ Fire failed: no missiles or score updated")
            return
        }
        // Get ships from the sceneView
        let ships = sceneView.ships
        guard ships.count > sceneView.targetIndex else {
            print("❌ Fire failed: no ships or invalid target index")
            return
        }
        guard !ships[sceneView.targetIndex].isDestroyed else {
            print("❌ Fire failed: target ship is destroyed")
            return
        }
        let ship = ships[sceneView.targetIndex]
        ship.targeted = true
        guard let missile = sceneView.helicopter.missiles.first(where: { !$0.fired }) else {
            print("❌ No available missiles to fire")
            return
        }
        missile.fired = true
        missile.addCollision()
        // Initialize missile position at helicopter's gun position
        guard let helicopterEntity = sceneView.helicopter.helicopter else {
            print("❌ No helicopter entity found")
            return
        }
        
        // Get helicopter's world position (through its anchor)
        let helicopterWorldPos: SIMD3<Float>
        if let parent = helicopterEntity.parent {
            print("🚁 Parent transform: \(parent.transform.translation)")
        }
        
        // Try to get world position from the helicopter anchor
        if let helicopterAnchor = sceneView.helicopterAnchor {
            helicopterWorldPos = helicopterAnchor.transform.translation
            print("🚁 Using helicopter anchor position: \(helicopterWorldPos)")
        } else if let parent = helicopterEntity.parent {
            helicopterWorldPos = parent.transform.translation
            print("🚁 Using parent position: \(helicopterWorldPos)")
        } else {
            helicopterWorldPos = helicopterEntity.transform.translation
            print("🚁 Using entity position: \(helicopterWorldPos)")
        }
        
        // Start missile from helicopter's gun position
        let gunOffset = SIMD3<Float>(0.0, 0.0, 0.2) // Slightly forward of helicopter
        let initialMissilePos = helicopterWorldPos + gunOffset
        
        // Move missile to world space and set position
        // Remove missile from helicopter parent hierarchy
        missile.entity.removeFromParent()
        
        // Make missile visible and appropriately sized
        missile.entity.isEnabled = true
        missile.entity.scale = SIMD3<Float>(repeating: 2.0) // Make missile bigger for visibility
        
        // Create world anchor for missile
        let missileAnchor = AnchorEntity(world: initialMissilePos)
        missileAnchor.addChild(missile.entity)
        sceneView.scene.addAnchor(missileAnchor)
        
        // Set missile local position to origin since it's now anchored at the correct world position
        missile.entity.transform.translation = SIMD3<Float>(0, 0, 0)
        
        // Point missile at target
        let targetPos = ship.entity.transform.translation
        missile.entity.look(
            at: targetPos,
            from: initialMissilePos,
            relativeTo: nil
        )
        print("🎯 Missile initial position: \(initialMissilePos)")
        print("🎯 Target position: \(targetPos)")
        print("🎯 Helicopter world position: \(helicopterWorldPos)")
        ApacheHelicopter.speed = 0
        missile.particleEntity?.isEnabled = true
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMissilePosition))
        displayLink.preferredFramesPerSecond = 60
        activeMissileTrackers[missile.id] = MissileTrackingInfo(
            missile: missile,
            target: ship,
            startTime: CACurrentMediaTime(),
            duration: 0, // Not used in this approach
            displayLink: displayLink,
            lastUpdateTime: CACurrentMediaTime()
        )
        displayLink.add(to: .main, forMode: .common)
    }
    
    @MainActor
    @objc private func updateMissilePosition(displayLink: CADisplayLink) {
        print("updateMissilePosition")
        guard let trackingInfo = activeMissileTrackers.first(where: { $0.value.displayLink === displayLink })?.value else {
            displayLink.invalidate()
            return
        }
        let missile = trackingInfo.missile
        let ship = trackingInfo.target
        if missile.hit {
            displayLink.invalidate()
            activeMissileTrackers[missile.id] = nil
            return
        }
        let deltaTime = displayLink.timestamp - trackingInfo.lastUpdateTime
        let speed: Float = 100
        let targetPos = ship.entity.transform.translation
        let currentPos = missile.entity.transform.translation
        // Debug missile position tracking
        if trackingInfo.frameCount < 3 {
            print("🚀 Frame \(trackingInfo.frameCount): Current pos: \(currentPos), Target pos: \(targetPos)")
        }
        // Check for invalid positions - including infinity
        if targetPos.x.isNaN || targetPos.y.isNaN || targetPos.z.isNaN ||
            currentPos.x.isNaN || currentPos.y.isNaN || currentPos.z.isNaN ||
            targetPos.x.isInfinite || targetPos.y.isInfinite || targetPos.z.isInfinite ||
            currentPos.x.isInfinite || currentPos.y.isInfinite || currentPos.z.isInfinite ||
            abs(currentPos.x) > 1000 || abs(currentPos.y) > 1000 || abs(currentPos.z) > 1000 {
            print("❌ Invalid positions detected - stopping missile tracking")
            print("❌ Current: \(currentPos), Target: \(targetPos)")
            displayLink.invalidate()
            activeMissileTrackers[missile.id] = nil
            return
        }
        // Check distance to target
        let distance = simd_distance(currentPos, targetPos)
        print("🎯 Missile \(missile.id) distance to target: \(distance)")
        print("🎯 Current pos: \(currentPos), Target pos: \(targetPos)")
        // If close enough to target, trigger hit
        if distance < 1.0 {
            print("💥 Missile hit target!")
            missile.hit = true
            ship.isDestroyed = true
            ship.removeShip()
            // Add explosion effect
            sceneView.addExplosion(at: targetPos)
            // Update score
            DispatchQueue.main.async {
                self.game.playerScore += 1
                self.game.updateScoreText()
                self.delegate?.missileManager(self, didUpdateScore: self.game.playerScore)
            }
            // Stop tracking this missile
            displayLink.invalidate()
            activeMissileTrackers[missile.id] = nil
            return
        }
        // Calculate direction safely with bounds checking
        let directionVector = targetPos - currentPos
        let directionLength = simd_length(directionVector)
        if directionLength > 0.001 && directionLength < 1000 {
            let direction = simd_normalize(directionVector)
            let movement = direction * speed * Float(deltaTime)
            // Verify movement is reasonable
            let movementLength = simd_length(movement)
            if movementLength > 0 && movementLength < 10.0 {
                let newPosition = currentPos + movement
                // Verify new position is reasonable
                if abs(newPosition.x) < 100 && abs(newPosition.y) < 100 && abs(newPosition.z) < 100 {
                    missile.entity.transform.translation = newPosition
                    missile.entity.look(
                        at: targetPos,
                        from: newPosition,
                        relativeTo: nil
                    )
                } else {
                    print("❌ New position would be invalid: \(newPosition)")
                    displayLink.invalidate()
                    activeMissileTrackers[missile.id] = nil
                }
            } else {
                print("❌ Movement too large: \(movementLength)")
                displayLink.invalidate()
                activeMissileTrackers[missile.id] = nil
            }
        } else {
            print("❌ Direction vector invalid - length: \(directionLength)")
            displayLink.invalidate()
            activeMissileTrackers[missile.id] = nil
        }
        var updatedInfo = trackingInfo
        updatedInfo.frameCount += 1
        updatedInfo.lastUpdateTime = displayLink.timestamp
        activeMissileTrackers[missile.id] = updatedInfo
        if updatedInfo.frameCount > 30 {
            NotificationCenter.default.post(
                name: .missileCanHit,
                object: self,
                userInfo: nil
            )
        }
    }
    
    // MARK: - Collision Handling
    
    @MainActor
    func handleContact(_ contact: CollisionEvents.Began) {
        let entityA = contact.entityA
        let entityB = contact.entityB
        let nameA = entityA.name
        let nameB = entityB.name
        let isMissileHit = (nameA.contains("Missile") && !nameB.contains("Missile")) ||
        (nameB.contains("Missile") && !nameA.contains("Missile"))
        guard isMissileHit else {
            print("❌ Not a missile hit: \(nameA) vs \(nameB)")
            return
        }
        let missileEntity = nameA.contains("Missile") ? entityA : entityB
        let shipEntity = nameA.contains("Missile") ? entityB : entityA
        guard
            let missile = Missile.getMissile(from: missileEntity),
            let ship = Ship.getShip(from: shipEntity)
        else { return }
        let shouldUpdateScore = !missile.hit
        missile.hit = true
        if shouldUpdateScore {
            DispatchQueue.main.async {
                self.game.playerScore += 1
                ApacheHelicopter.speed = 0
                self.game.updateScoreText()
                NotificationCenter.default.post(
                    name: .updateScore,
                    object: self,
                    userInfo: nil
                )
            }
        }
        DispatchQueue.main.async {
            ship.isDestroyed = true
            ship.removeShip()
            self.sceneView.addExplosion(at: shipEntity.transform.translation)
        }
        missile.particleEntity?.isEnabled = false
        missileEntity.removeFromParent()
        activeMissileTrackers[missile.id] = nil
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func handleMissileHit(missile: Missile, ship: Ship, at position: SIMD3<Float>) {
        print("💥 HIT DETECTED!")
        missile.hit = true
        ship.isDestroyed = true
        DispatchQueue.main.async {
            self.game.playerScore += 1
            ApacheHelicopter.speed = 0
            self.game.updateScoreText()
            NotificationCenter.default.post(
                name: .updateScore,
                object: self,
                userInfo: nil
            )
        }
        DispatchQueue.main.async {
            ship.removeShip()
            self.sceneView.addExplosion(at: position)
        }
        cleanupMissile(missile)
        print("✅ Missile hit processing complete.")
    }
    
    @MainActor
    private func cleanupMissile(_ missile: Missile) {
        missile.particleEntity?.isEnabled = false
        missile.entity.removeFromParent()
        activeMissileTrackers[missile.id] = nil
    }
}
