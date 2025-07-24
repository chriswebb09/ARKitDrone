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

// MARK: - Missile Physics (Simplified)

// Simple missile physics constants
private struct MissileConstants {
    static let speed: Float = 12.0
    static let hitRadius: Float = 3.5
    static let maxLifetime: TimeInterval = 90.0
    static let predictionScale: Float = 15.0
    static let maxWorldBounds: Float = 100.0
}

// MARK: - MissileManager
@MainActor
class MissileManager {
    
    // MARK: - Properties
    
    var activeMissileTrackers: [String: MissileTrackingInfo] = [:]
    var game: Game
    var sceneView: GameSceneView
    weak var delegate: MissileManagerDelegate?
    
    // Simplified physics - no separate classes needed
    
//    // Effects system
//    private let weaponEffectsManager: WeaponEffectsManager
//    private var missileTrails: [String: TrailEffect] = [:]
    
    // Rate limiting for missile firing
    private var lastFireTime: TimeInterval = 0
    private let minimumFireInterval: TimeInterval = 1.0 // 1 second between missiles
    private let maxActiveMissiles: Int = 3 // Maximum missiles in flight at once
    
    // Reference to game manager for accessing helicopter objects
    weak var gameManager: GameManager?
    
    // Reference to ship manager for getting current target
    weak var shipManager: ShipManager?
    
    // Local player reference - passed in to ensure consistency
    let localPlayer: Player
    
    // MARK: - Init
    
    init(game: Game, sceneView: GameSceneView, gameManager: GameManager? = nil, localPlayer: Player) {
        self.game = game
        self.sceneView = sceneView
        self.gameManager = gameManager
        self.localPlayer = localPlayer
        
        // No complex initialization needed
        
//        // Initialize effects manager (create if not provided)
//        if let effects = weaponEffectsManager {
//            self.weaponEffectsManager = effects
//        } else {
//            self.weaponEffectsManager = WeaponEffectsManager(scene: sceneView.scene)
//        }
    }
    
    // MARK: - Simplified Missile Physics
    
    /// Update missile position toward target (simplified)
    private func updateMissile(_ missile: Missile, target: Ship, deltaTime: TimeInterval) -> Bool {
        let currentPos = missile.entity.transform.translation
        let targetPos = target.entity.transform.translation
        
        // Calculate direction and movement
        let direction = simd_normalize(targetPos - currentPos)
        let movement = direction * MissileConstants.speed * Float(deltaTime)
        let newPosition = currentPos + movement
        
        // Update missile position and rotation
        missile.entity.transform.translation = newPosition
        missile.entity.transform.rotation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: direction)
        
        // Check for hit
        let distance = simd_distance(newPosition, targetPos)
        return distance < MissileConstants.hitRadius
    }
    
    /// Check if position is valid (simplified)
    private func isValidPosition(_ position: SIMD3<Float>) -> Bool {
        return !position.x.isNaN && !position.y.isNaN && !position.z.isNaN &&
               abs(position.x) < MissileConstants.maxWorldBounds &&
               abs(position.y) < MissileConstants.maxWorldBounds &&
               abs(position.z) < MissileConstants.maxWorldBounds
    }
    
    // MARK: - Fire Missile (Simplified)
    
    /// Check if missile can be fired (simplified)
    private func canFire() -> Bool {
        // Basic rate limiting
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastFireTime >= minimumFireInterval else { return false }
        
        // Check active missile limit
        guard activeMissileTrackers.count < maxActiveMissiles else { return false }
        
        // Check if we have helicopter and target
        guard let helicopter = gameManager?.getHelicopter(for: localPlayer),
              let helicopterEntity = helicopter.helicopterEntity,
              let target = shipManager?.getCurrentTarget() else { return false }
        
        // Check if missiles are armed
        guard helicopter.missilesArmed() else { return false }
        
        // Check if we have available missiles
        let availableMissiles = helicopterEntity.missiles.filter { !$0.fired }
        return !availableMissiles.isEmpty
    }
    
    /// Get helicopter position (simplified)
    private func getHelicopterPosition() -> SIMD3<Float>? {
        guard let helicopter = gameManager?.getHelicopter(for: localPlayer) else { return nil }
        
        return helicopter.anchorEntity?.transform.translation 
            ?? helicopter.helicopterEntity?.helicopter?.transform.translation
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
        guard canFire() else { return }
        
        lastFireTime = CACurrentMediaTime()
        
        // Get required components
        guard let ship = shipManager?.getCurrentTarget(),
              let helicopter = gameManager?.getHelicopter(for: localPlayer),
              let helicopterEntity = helicopter.helicopterEntity,
              let missile = helicopterEntity.missiles.first(where: { !$0.fired }),
              let helicopterPos = getHelicopterPosition() else { return }
        
        // Setup missile
        ship.targeted = true
        missile.fired = true
        missile.addCollision()
        
        // Position missile at helicopter gun
        let gunOffset = SIMD3<Float>(0.0, 0.0, 0.2)
        let missileStartPos = helicopterPos + gunOffset
        configureMissile(missile, at: missileStartPos)
        
        // Point missile at target
        missile.entity.look(at: ship.entity.transform.translation, from: missileStartPos, relativeTo: nil)
        
        // Start tracking
        startMissileTracking(missile: missile, target: ship)
    }
    
    /// Start missile tracking (simplified)
    private func startMissileTracking(missile: Missile, target: Ship) {
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMissilePosition))
        displayLink.preferredFramesPerSecond = 60
        
        activeMissileTrackers[missile.id] = MissileTrackingInfo(
            missile: missile,
            target: target,
            startTime: CACurrentMediaTime(),
            duration: 0,
            displayLink: displayLink,
            lastUpdateTime: CACurrentMediaTime()
        )
        
        displayLink.add(to: .main, forMode: .common)
    }
    
    
    /// Update missile position each frame (simplified)
    @objc private func updateMissilePosition(displayLink: CADisplayLink) {
        guard let trackingInfo = activeMissileTrackers.first(where: { $0.value.displayLink === displayLink })?.value else {
            displayLink.invalidate()
            return
        }
        
        let missile = trackingInfo.missile
        let ship = trackingInfo.target
        
        // Check if missile is done or expired
        if missile.hit || (CACurrentMediaTime() - trackingInfo.startTime > MissileConstants.maxLifetime) {
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        // Update missile physics
        let deltaTime = displayLink.timestamp - trackingInfo.lastUpdateTime
        let hitDetected = updateMissile(missile, target: ship, deltaTime: deltaTime)
        
        if hitDetected {
            handleMissileHit(missile: missile, ship: ship, at: missile.entity.transform.translation)
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        // Update tracking info
        var updatedInfo = trackingInfo
        updatedInfo.frameCount += 1
        updatedInfo.lastUpdateTime = displayLink.timestamp
        activeMissileTrackers[missile.id] = updatedInfo
        
        // Notify after initial frames  
        if updatedInfo.frameCount > 30 {
            NotificationCenter.default.post(name: .missileCanHit, object: self)
        }
    }
    
    // MARK: - Hit Handling (Simplified)
    
    /// Handle collision-based missile hits
    @MainActor
    func handleContact(_ contact: CollisionEvents.Began) {
        let entityA = contact.entityA
        let entityB = contact.entityB
        
        // Check if this is a missile hit
        let isMissileHit = (entityA.name.contains("Missile") && !entityB.name.contains("Missile")) ||
                          (entityB.name.contains("Missile") && !entityA.name.contains("Missile"))
        guard isMissileHit else { return }
        
        // Get missile and ship entities
        let missileEntity = entityA.name.contains("Missile") ? entityA : entityB
        let shipEntity = entityA.name.contains("Missile") ? entityB : entityA
        
        guard let missile = Missile.getMissile(from: missileEntity),
              let ship = Ship.getShip(from: shipEntity) else { return }
        
        handleMissileHit(missile: missile, ship: ship, at: shipEntity.transform.translation)
    }
    
    // MARK: - Private Helpers
    
    /// Handle missile hit (simplified)
    private func handleMissileHit(missile: Missile, ship: Ship, at position: SIMD3<Float>) {
        guard !missile.hit else { return }  // Prevent double hits
        
        missile.hit = true
        ship.isDestroyed = true
        
        // Update score and notify
        game.playerScore += 1
        game.setEnemyDestroyed()
        NotificationCenter.default.post(name: .updateScore, object: self)
        NotificationCenter.default.post(name: .shipDestroyed, object: self)
        
        // Visual effects
        ship.removeShip()
        sceneView.addExplosion(at: position)
        
        // Cleanup
        cleanupMissile(missile)
        
        // Notify delegate
        delegate?.missileManager(self, didUpdateScore: game.playerScore)
    }
    
    // MARK: - Cleanup (Simplified)
    
    /// Cleanup missile tracking and DisplayLink
    private func cleanupMissile(displayLink: CADisplayLink, missileID: String) {
        displayLink.invalidate()
        
        if let trackingInfo = activeMissileTrackers[missileID] {
            resetMissile(trackingInfo.missile)
        }
        
        activeMissileTrackers.removeValue(forKey: missileID)
    }
    
    /// Cleanup missile entity and tracking
    private func cleanupMissile(_ missile: Missile) {
        resetMissile(missile)
        activeMissileTrackers.removeValue(forKey: missile.id)
    }
    
    /// Reset missile for reuse
    private func resetMissile(_ missile: Missile) {
        missile.particleEntity?.isEnabled = false
        missile.entity.removeFromParent()
        missile.fired = false
        missile.hit = false
    }
    
    /// Reset all active missiles (simplified)
    func resetAllMissiles() {
        for (_, trackingInfo) in activeMissileTrackers {
            trackingInfo.displayLink.invalidate()
            resetMissile(trackingInfo.missile)
        }
        activeMissileTrackers.removeAll()
    }
    
    /// Cleanup expired missiles (simplified)
    func cleanupExpiredMissiles() {
        let currentTime = CACurrentMediaTime()
        let expiredTrackers = activeMissileTrackers.filter { 
            currentTime - $0.value.startTime > MissileConstants.maxLifetime 
        }
        
        for (missileId, trackingInfo) in expiredTrackers {
            cleanupMissile(displayLink: trackingInfo.displayLink, missileID: missileId)
        }
    }
    
    /// Force cleanup all missiles (for testing)
    func cleanupAllMissiles() {
        let allTrackers = Array(activeMissileTrackers)
        for (missileId, trackingInfo) in allTrackers {
            cleanupMissile(displayLink: trackingInfo.displayLink, missileID: missileId)
        }
    }
    
    // MARK: - Network Synchronization Methods
    
    func handleNetworkMissileFired(_ data: MissileFireData) {
        // For network games, create visual representation of remote missile
        // This is called when another player fires a missile
        guard let targetShip = shipManager?.ships.first(where: { $0.id == data.targetShipId }) else { return }
        
        // Create visual missile entity at network position
        // In a full implementation, you'd create a visual-only missile
        // For now, just log the network event
        print("🚀 Remote missile fired by player \(data.playerId) targeting ship \(data.targetShipId)")
    }
    
    func handleNetworkMissilePosition(_ data: MissileSyncData) {
        // For network games, update visual representation of remote missile
        // In a full implementation, you'd track remote missiles separately
        print("🚀 Remote missile position updated: \(data.missileId)")
    }
    
    func handleNetworkMissileHit(_ data: MissileHitData) {
        // Handle remote missile hit for network games
        guard let ship = shipManager?.ships.first(where: { $0.id == data.shipId }) else { return }
        
        // Apply damage to ship from remote missile
        ship.takeDamage(100) // Standard missile damage
        
        // Create explosion effect at hit position
        shipManager?.addExplosion(contactPoint: data.hitPosition)
        
        print("💥 Remote missile hit ship \(data.shipId) by player \(data.playerId)")
    }
}
