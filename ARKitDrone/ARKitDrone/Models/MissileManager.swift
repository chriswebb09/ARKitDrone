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
    
    // Reference to game manager for accessing helicopter objects
    weak var gameManager: GameManager?
    
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
        
        if helicopterEntity.missiles.isEmpty || game.scoreUpdated {
            print("Fire failed: no missiles or score updated")
            return false
        }
        guard sceneView.targetIndex < sceneView.ships.count else {
            print("Fire failed: no ships or invalid target index")
            return false
        }
        if sceneView.ships[sceneView.targetIndex].isDestroyed {
            print("Fire failed: target ship is destroyed")
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
        if !canFire(game: game) { return }
        
        let ships = sceneView.ships
        let ship = ships[sceneView.targetIndex]
        ship.targeted = true
        
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
            print("No helicopter RealityKit entity found")
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
        
        let deltaTime = displayLink.timestamp - trackingInfo.lastUpdateTime
        let speed: Float = 5  // Much slower for 10+ second missile flight
        let targetPos = ship.entity.transform.translation
        let currentPos = missile.entity.transform.translation
        
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
        print("Missile \(missile.id) distance to target: \(distance)")
        print("Current pos: \(currentPos), Target pos: \(targetPos)")
        
        if distance < 1.0 {
            handleMissileHit(missile: missile, ship: ship, at: targetPos)
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let directionVector = targetPos - currentPos
        let directionLength = simd_length(directionVector)
        
        guard directionLength > 0.001 && directionLength < 1000 else {
            print("Direction vector invalid - length: \(directionLength)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let direction = simd_normalize(directionVector)
        let movement = direction * speed * Float(deltaTime)
        let movementLength = simd_length(movement)
        
        guard movementLength > 0 && movementLength < 10.0 else {
            print("Movement too large: \(movementLength)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        let newPosition = currentPos + movement
        
        guard abs(newPosition.x) < 100 && abs(newPosition.y) < 100 && abs(newPosition.z) < 100 else {
            print("New position would be invalid: \(newPosition)")
            cleanupMissile(displayLink: displayLink, missileID: missile.id)
            return
        }
        
        missile.entity.transform.translation = newPosition
        missile.entity.look(at: targetPos, from: newPosition, relativeTo: nil)
        
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
        print("Missile hit processing complete.")
    }
    
    private func cleanupMissile(displayLink: CADisplayLink, missileID: String) {
        displayLink.invalidate()
        activeMissileTrackers[missileID] = nil
    }
    
    @MainActor
    private func cleanupMissile(_ missile: Missile) {
        missile.particleEntity?.isEnabled = false
        missile.entity.removeFromParent()
        activeMissileTrackers[missile.id] = nil
    }
}
