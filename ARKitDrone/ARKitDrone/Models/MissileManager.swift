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
@MainActor
class MissileManager {
    
    // MARK: - Properties
    
    var activeMissileTrackers: [String: MissileTrackingInfo] = [:]
    var game: Game
    var sceneView: GameSceneView
    let missileSpeed: Float = 12 // Increased speed for better targeting
    weak var delegate: MissileManagerDelegate?
    
    // Rate limiting for missile firing
    private var lastFireTime: TimeInterval = 0
    private let minimumFireInterval: TimeInterval = 1.0 // 1 second between missiles
    private let maxActiveMissiles: Int = 3 // Maximum missiles in flight at once
    private let missileLifetime: TimeInterval = 90.0 // 90 seconds before missile auto-cleanup
    
    // Reference to game manager for accessing helicopter objects
    weak var gameManager: GameManager?
    
    // Reference to targeting manager for getting current target
    weak var targetingManager: TargetingManager?
    
    // Local player reference - passed in to ensure consistency
    private let localPlayer: Player
    
    // MARK: - Init
    
    init(game: Game, sceneView: GameSceneView, gameManager: GameManager? = nil, localPlayer: Player) {
        self.game = game
        self.sceneView = sceneView
        self.gameManager = gameManager
        self.localPlayer = localPlayer
    }
    
    // MARK: - Fire Missile
    @MainActor
    private func canFire(game: Game) -> Bool {
        print("🔍 Debugging helicopter lookup:")
        print("Local player: \(localPlayer.username)")
        print("Available helicopters: \(gameManager?.getAllHelicopters().map { $0.owner?.username ?? "unknown" } ?? [])")
        
        // Get local helicopter through HelicopterObject system
        guard let localHelicopter = gameManager?.getHelicopter(for: localPlayer) else {
            print("❌ Fire failed: no local helicopter entity")
            print("GameManager: \(gameManager != nil ? "present" : "nil")")
            if let gm = gameManager {
                print("Helicopter count: \(gm.getAllHelicopters().count)")
                for helicopter in gm.getAllHelicopters() {
                    print("  - Owner: \(helicopter.owner?.username ?? "nil"), equals local: \(helicopter.owner == localPlayer)")
                }
            }
            return false
        }
        
        guard let helicopterEntity = localHelicopter.helicopterEntity else {
            print("❌ Fire failed: helicopter entity is nil")
            return false
        }
        
        if helicopterEntity.missiles.isEmpty {
            print("Fire failed: no missiles available")
            return false
        }
        
        // Check if there are any available (unfired) missiles
        let availableMissiles = helicopterEntity.missiles.filter { !$0.fired }
        if availableMissiles.isEmpty {
            print("Fire failed: no available missiles (all \(helicopterEntity.missiles.count) missiles are fired)")
            return false
        }
        
        print("🚀 Available missiles: \(availableMissiles.count)/\(helicopterEntity.missiles.count)")
        
        // Check if we have a valid target through targeting manager
        guard let targetingManager = targetingManager,
              targetingManager.hasValidTarget() else {
            print("Fire failed: no valid target available")
            return false
        }
        return true
    }
    
    @MainActor
    private func getHelicopterWorldPosition() -> SIMD3<Float>? {
        // Get position through HelicopterObject system
        guard let localHelicopter = gameManager?.getHelicopter(for: localPlayer) else {
            return nil
        }
        
        if let anchor = localHelicopter.anchorEntity {
            return anchor.transform.translation
        } else if let helicopterEntity = localHelicopter.helicopterEntity?.helicopter {
            if let parent = helicopterEntity.parent {
                return parent.transform.translation
            } else {
                return helicopterEntity.transform.translation
            }
        }
        return nil
    }
    
    @MainActor
    private func configureMissile(_ missile: Missile, at position: SIMD3<Float>) {
        missile.entity.removeFromParent()
        missile.entity.isEnabled = true
        missile.entity.scale = SIMD3<Float>(repeating: 2.0)
        missile.entity.transform.translation = .zero
        
        let anchor = AnchorEntity(world: position)
        anchor.addChild(missile.entity)
        sceneView.scene.addAnchor(anchor)
        
        missile.particleEntity?.isEnabled = true
    }
    
    @MainActor
    func fire(game: Game) {
        // Rate limiting check
        let currentTime = CACurrentMediaTime()
        if currentTime - lastFireTime < minimumFireInterval {
            print("🚫 Missile fire blocked - too soon after last fire (wait \(minimumFireInterval - (currentTime - lastFireTime))s)")
            return
        }
        
        // Check maximum active missiles
        if activeMissileTrackers.count >= maxActiveMissiles {
            print("🚫 Missile fire blocked - too many active missiles (\(activeMissileTrackers.count)/\(maxActiveMissiles))")
            return
        }
        
        if !canFire(game: game) { return }
        
        lastFireTime = currentTime
        
        // Get current target from targeting manager
        guard let ship = targetingManager?.getCurrentTarget() else {
            print("No valid target available for missile")
            return
        }
        ship.targeted = true
        
        print("🚀 Firing missile at target ship \(ship.id.prefix(8)) - Active missiles: \(activeMissileTrackers.count)")
        
        // Get missile through HelicopterObject system
        guard let localHelicopter = gameManager?.getHelicopter(for: localPlayer),
              let helicopterApache = localHelicopter.helicopterEntity else {
            print("No local helicopter entity found")
            return
        }
        
        guard let missile = helicopterApache.missiles.first(where: { !$0.fired }) else {
            print("No available missiles to fire")
            return
        }
        missile.fired = true
        missile.addCollision()
        
        // Initialize missile position at helicopter's gun position
        guard let helicopterEntity = helicopterApache.helicopter else {
            print("No helicopter entity found")
            return
        }
        // Get helicopter's world position (through its anchor)
        let helicopterWorldPos: SIMD3<Float>
        if let parent = helicopterEntity.parent {
            print("Parent transform: \(parent.transform.translation)")
        }
        guard let helicopterPos = getHelicopterWorldPosition() else {
            return
        }
        helicopterWorldPos = helicopterPos
        
        // Start missile from helicopter's gun position
        let gunOffset = SIMD3<Float>(0.0, 0.0, 0.2) // Slightly forward of helicopter
        let initialMissilePos = helicopterWorldPos + gunOffset
        // Move missile to world space and set position
        configureMissile(missile, at: initialMissilePos)
        // Point missile at target
        let targetPos = ship.entity.transform.translation
        missile.entity.look(
            at: targetPos,
            from: initialMissilePos,
            relativeTo: nil
        )
        print("Missile initial position: \(initialMissilePos)")
        print("Target position: \(targetPos)")
        print("Helicopter world position: \(helicopterWorldPos)")
        ApacheHelicopter.speed = 0
        
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateMissilePosition)
        )
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
    private func isInvalid(position: SIMD3<Float>) -> Bool {
        return position.x.isNaN || position.y.isNaN || position.z.isNaN ||
        position.x.isInfinite || position.y.isInfinite || position.z.isInfinite ||
        abs(position.x) > 1000 || abs(position.y) > 1000 || abs(position.z) > 1000
    }
    
    @MainActor
    @objc private func updateMissilePosition(displayLink: CADisplayLink) {
        guard let trackingInfo = activeMissileTrackers.first(where: { $0.value.displayLink === displayLink })?.value else {
            displayLink.invalidate()
            return
        }
        
        let missile = trackingInfo.missile
        let ship = trackingInfo.target
        
        if missile.hit {
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        // Check if missile has exceeded its lifetime (90 seconds)
        let currentTime = CACurrentMediaTime()
        if currentTime - trackingInfo.startTime > missileLifetime {
            print("⏰ Missile \(missile.id.prefix(8)) expired after \(missileLifetime) seconds - cleaning up")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let deltaTime = displayLink.timestamp - trackingInfo.lastUpdateTime
        let speed: Float = missileSpeed // Use class property for consistent speed
        // Get missile's world position by combining anchor and entity positions
        let currentPos: SIMD3<Float>
        if let parent = missile.entity.parent {
            currentPos = parent.transform.translation + missile.entity.transform.translation
        } else {
            currentPos = missile.entity.transform.translation
        }
        
        // Get ship position with predictive targeting for moving targets
        let currentShipPos = ship.entity.transform.translation
        let shipVelocity = ship.velocity
        
        // Predict where the ship will be based on missile travel time
        let distanceToShip = simd_distance(currentPos, currentShipPos)
        let timeToImpact = distanceToShip / max(speed, 0.1) // Avoid division by zero
        
        // Add prediction for moving targets (scaled for better accuracy)
        let targetPos = currentShipPos + (shipVelocity * timeToImpact * 15.0)
        
        if trackingInfo.frameCount < 3 {
            print("Frame \(trackingInfo.frameCount): Current pos: \(currentPos), Target pos: \(targetPos)")
        }
        
        if isInvalid(position: targetPos) || isInvalid(position: currentPos) {
            print("Invalid positions detected - stopping missile tracking")
            print("Current: \(currentPos), Target: \(targetPos)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let distance = simd_distance(currentPos, targetPos)
        
        // Only print missile tracking info every 30 frames (1 second at 30fps) to reduce spam
        if trackingInfo.frameCount % 30 == 0 {
            print("🚀 Missile \(missile.id.prefix(8)) tracking:")
            print("  Distance to target: \(distance)")
            print("  Current pos: \(currentPos)")
            print("  Target pos: \(targetPos)")
            print("  Ship velocity: \(ship.velocity)")
            print("  Ship destroyed: \(ship.isDestroyed)")
        }
        
        if distance < 3.5 {  // Further increased hit detection range for better success rate
            print("🎯 HIT DETECTED! Distance: \(distance)")
            handleMissileHit(missile: missile, ship: ship, at: targetPos)
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let directionVector = targetPos - currentPos
        let directionLength = simd_length(directionVector)
        
        if trackingInfo.frameCount < 3 {
            print("Direction vector: \(directionVector), length: \(directionLength)")
        }
        
        guard directionLength > 0.001 && directionLength < 1000 else {
            print("Direction vector invalid - length: \(directionLength)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let direction = simd_normalize(directionVector)
        let movement = direction * speed * Float(deltaTime)
        
        if trackingInfo.frameCount < 3 {
            print("Normalized direction: \(direction), movement: \(movement), deltaTime: \(deltaTime)")
        }
        let movementLength = simd_length(movement)
        
        guard movementLength > 0 && movementLength < 10.0 else {
            print("Movement too large: \(movementLength)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let newWorldPosition = currentPos + movement
        
        guard abs(newWorldPosition.x) < 100 && abs(newWorldPosition.y) < 100 && abs(newWorldPosition.z) < 100 else {
            print("New position would be invalid: \(newWorldPosition)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        // Convert world position back to local position relative to anchor
        if let parent = missile.entity.parent {
            missile.entity.transform.translation = newWorldPosition - parent.transform.translation
        } else {
            missile.entity.transform.translation = newWorldPosition
        }
        
        // Orient missile towards target without using look(at:) which might interfere
        if simd_length(directionVector) > 0.001 {
            let targetRotation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: direction)
            missile.entity.transform.rotation = targetRotation
        }
        
        var updatedInfo = trackingInfo
        updatedInfo.frameCount += 1
        updatedInfo.lastUpdateTime = displayLink.timestamp
        activeMissileTrackers[missile.id] = updatedInfo
        
        if updatedInfo.frameCount > 30 {
            NotificationCenter.default.post(name: .missileCanHit, object: self)
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
            print("Not a missile hit: \(nameA) vs \(nameB)")
            return
        }
        let missileEntity = nameA.contains("Missile") ? entityA : entityB
        let shipEntity = nameA.contains("Missile") ? entityB : entityA
        guard
            let missile = Missile.getMissile(
                from: missileEntity
            ),
            let ship = Ship.getShip(
                from: shipEntity
            )
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
            self.sceneView.addExplosion(
                at: shipEntity.transform.translation
            )
        }
        missile.particleEntity?.isEnabled = false
        missileEntity.removeFromParent()
        activeMissileTrackers[missile.id] = nil
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func handleMissileHit(missile: Missile, ship: Ship, at position: SIMD3<Float>) {
        print("HIT DETECTED!")
        missile.hit = true
        ship.isDestroyed = true
        DispatchQueue.main.async {
            print("🎯 Before score update: \(self.game.playerScore)")
            self.game.playerScore += 1
            print("🎯 After score update: \(self.game.playerScore)")
            ApacheHelicopter.speed = 0
            self.game.updateScoreText()
            print("🎯 Score text updated: \(self.game.scoreTextString)")
            NotificationCenter.default.post(
                name: .updateScore,
                object: self,
                userInfo: nil
            )
            print("🎯 Score update notification sent")
        }
        DispatchQueue.main.async {
            ship.removeShip()
            self.sceneView.addExplosion(at: position)
        }
        cleanupMissile(missile)
        print("Missile hit processing complete.")
    }
    
    private func cleanupMissile(displayLink: CADisplayLink, missileID: String) {
        displayLink.invalidate()
        
        // Reset missile flags if we still have reference to it
        if let trackingInfo = activeMissileTrackers[missileID] {
            trackingInfo.missile.fired = false
            trackingInfo.missile.hit = false
            print("🔄 Missile \(missileID.prefix(8)) reset for reuse")
        }
        
        activeMissileTrackers[missileID] = nil
    }
    
    @MainActor
    private func cleanupMissile(_ missile: Missile) {
        missile.particleEntity?.isEnabled = false
        missile.entity.removeFromParent()
        
        // Reset missile flags for reuse
        missile.fired = false
        missile.hit = false
        
        activeMissileTrackers[missile.id] = nil
        print("🔄 Missile \(missile.id.prefix(8)) reset for reuse")
    }
    
    // MARK: - Missile Reset/Cleanup
    
    /// Reset all active missiles (useful for game restart or emergency cleanup)
    @MainActor
    func resetAllMissiles() {
        print("🧹 Resetting all \(activeMissileTrackers.count) active missiles")
        
        for (missileId, trackingInfo) in activeMissileTrackers {
            trackingInfo.displayLink.invalidate()
            trackingInfo.missile.particleEntity?.isEnabled = false
            trackingInfo.missile.entity.removeFromParent()
            trackingInfo.missile.hit = true
            trackingInfo.missile.fired = false // Reset for reuse
        }
        
        activeMissileTrackers.removeAll()
        print("✅ All missiles reset")
    }
    
    /// Cleanup expired missiles (called periodically)
    @MainActor
    func cleanupExpiredMissiles() {
        let currentTime = CACurrentMediaTime()
        var expiredMissiles: [String] = []
        
        for (missileId, trackingInfo) in activeMissileTrackers {
            if currentTime - trackingInfo.startTime > missileLifetime {
                expiredMissiles.append(missileId)
            }
        }
        
        for missileId in expiredMissiles {
            if let trackingInfo = activeMissileTrackers[missileId] {
                print("⏰ Cleaning up expired missile \(missileId.prefix(8))")
                cleanupMissile(displayLink: trackingInfo.displayLink, missileID: missileId)
            }
        }
        
        if !expiredMissiles.isEmpty {
            print("🧹 Cleaned up \(expiredMissiles.count) expired missiles")
        }
    }
}
