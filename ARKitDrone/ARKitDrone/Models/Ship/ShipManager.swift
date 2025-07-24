//
//  ShipManager.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import ARKit

@MainActor
class ShipManager {
    
    var game: Game
    var arView: ARView
    var ships: [Ship] = []
    var helicopterEntity: Entity?
    var targetIndex = 0
    var attack: Bool = false
    var shipsSetup: Bool = false
    
    // Attack timing properties
    private var lastAttackTime: TimeInterval = 0
    private let attackCooldown: TimeInterval = 3.0  // 3 seconds between attacks
    private let attackDelay: TimeInterval = 5.0     // 5 seconds before first attack
    private var gameStartTime: TimeInterval = 0
    
    // MARK: - Entity Management
    
    /// EntityManager for centralized ship lifecycle management
    var entityManager: EntityManager?
    
    // MARK: - Targeting System (merged from TargetingManager)
    
    var isAutoTargeting: Bool = true
    private var targetIndicators: [String: ReticleEntity] = [:]
    
    struct LocalConstants {
        static let f35Scene = "F-35B_Lightning_II"
        static let f35Node = "F_35B"
    }
    
    init(game: Game, arView: ARView, entityManager: EntityManager? = nil) {
        self.game = game
        self.arView = arView
        self.entityManager = entityManager
    }
    
    // REPLACE setupShips() method:
    func setupShips() async {
        guard !shipsSetup else {
            print("⚠️ Ships already setup, skipping")
            return
        }
        
        do {
            // Use AsyncModelLoader
            let f35Entity = try await AsyncModelLoader.shared.loadModel(named: "F-35B_Lightning_II")
            // Create ships in parallel
            await withTaskGroup(of: Ship?.self) { group in
                for i in 1...20 {
                    group.addTask { @MainActor in
                        let shipEntity = f35Entity.clone(recursive: true)
                        shipEntity.name = "F_35B \(i)"
                        let randomOffset = SIMD3<Float>(
                            x: Float.random(in: -10.0...10.0),
                            y: Float.random(in: 2.0...8.0),
                            z: Float.random(in: 5.0...15.0)
                        )
                        
                        // Validate position values
                        guard !randomOffset.x.isNaN && !randomOffset.y.isNaN && !randomOffset.z.isNaN else {
                            print("❌ Invalid ship position generated, skipping ship \(i)")
                            return nil
                        }
                        
                        print("🚢 Creating ship \(i) at position: \(randomOffset)")
                        let anchor = AnchorEntity(
                            world: randomOffset
                        )
                        anchor.addChild(shipEntity)
                        self.arView.scene.addAnchor(anchor)
                        // No need to set shipEntity.transform.translation since anchor is positioned
                        
                        // Use safer scale value (10% instead of 1%)
                        let safeScale = SIMD3<Float>(x: 0.1, y: 0.1, z: 0.1)
                        shipEntity.transform.scale = safeScale
                        print("🚢 Ship \(i) configured with scale: 0.1 and position: \(shipEntity.transform.translation)")
                        let ship = Ship(entity: shipEntity)
                        ship.num = i
                        
                        // Register with EntityManager if available
                        if let entityManager = self.entityManager {
                            return entityManager.register(ship)
                        }
                        
                        return ship
                    }
                }
                // Collect results
                for await ship in group {
                    if let ship = ship {
                        self.ships.append(ship)
                        print("🚢 Ship \(ship.num ?? 0) created and registered")
                    }
                }
            }
            // Target setup now handled by TargetingManager
            self.shipsSetup = true
            print("✅ Ship setup completed: \(self.ships.count) ships created and ready")
            // Sync to GameSceneView
            if let gameRealityView = self.arView as? GameSceneView {
                gameRealityView.ships = self.ships
                print("🔄 Ships synced to GameSceneView")
            }
            
        } catch {
            print("❌ Failed to load ship model: \(error)")
        }
    }
    
    // MARK: - Targeting (simplified from TargetingManager)
    
    func getCurrentTarget() -> Ship? {
        let availableShips = ships.filter { !$0.isDestroyed }
        guard !availableShips.isEmpty else { return nil }
        
        // If current target is invalid, find a new one
        if targetIndex >= ships.count || (targetIndex < ships.count && ships[targetIndex].isDestroyed) {
            if isAutoTargeting {
                updateAutoTarget()
            } else {
                // Find first available ship
                for (index, ship) in ships.enumerated() {
                    if !ship.isDestroyed {
                        targetIndex = index
                        break
                    }
                }
            }
        }
        
        // Double-check that we have a valid target
        if targetIndex < ships.count && !ships[targetIndex].isDestroyed {
            return ships[targetIndex]
        }
        
        // If we still don't have a valid target, return the first available ship
        for (index, ship) in ships.enumerated() {
            if !ship.isDestroyed {
                targetIndex = index
                return ship
            }
        }
        
        return nil
    }
    
    func updateAutoTarget() {
        guard let helicopterPos = helicopterEntity?.transform.translation else { return }
        
        let availableShips = ships.enumerated().compactMap { (index, ship) -> (Int, Float)? in
            guard !ship.isDestroyed else { return nil }
            let distance = simd_distance(helicopterPos, ship.entity.transform.translation)
            return (index, distance)
        }
        
        // Find nearest ship
        if let nearestTarget = availableShips.min(by: { $0.1 < $1.1 }) {
            setTarget(index: nearestTarget.0)
        }
    }
    
    func switchToNextTarget() {
        let availableShips = ships.enumerated().compactMap { (index, ship) -> Int? in
            guard !ship.isDestroyed else { return nil }
            return index
        }
        
        guard !availableShips.isEmpty else { return }
        
        if let currentIndex = availableShips.firstIndex(of: targetIndex) {
            let nextIndex = (currentIndex + 1) % availableShips.count
            setTarget(index: availableShips[nextIndex])
        } else {
            setTarget(index: availableShips[0])
        }
        
        isAutoTargeting = false
    }
    
    func switchToPreviousTarget() {
        let availableShips = ships.enumerated().compactMap { (index, ship) -> Int? in
            guard !ship.isDestroyed else { return nil }
            return index
        }
        
        guard !availableShips.isEmpty else { return }
        
        if let currentIndex = availableShips.firstIndex(of: targetIndex) {
            let previousIndex = currentIndex == 0 ? availableShips.count - 1 : currentIndex - 1
            setTarget(index: availableShips[previousIndex])
        } else {
            setTarget(index: availableShips[0])
        }
        
        isAutoTargeting = false
    }
    
    private func setTarget(index: Int) {
        // Remove old target indicator
        if targetIndex < ships.count {
            let oldShip = ships[targetIndex]
            oldShip.square?.removeFromParent()
            oldShip.square = nil
            oldShip.targetAdded = false
        }
        
        targetIndex = index
        
        // Add new target indicator
        guard index < ships.count else { return }
        let ship = ships[index]
        let square = ReticleEntity()
        ship.square = square
        ship.targetAdded = true
        square.transform.translation = ship.entity.transform.translation
        
        if let parent = ship.entity.parent {
            parent.addChild(square)
        }
        
        targetIndicators[ship.id] = square
    }
    
    func addExplosion(contactPoint: SIMD3<Float>) {
        // Create simple explosion effect
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(
                color: .orange,
                isMetallic: false
            )]
        )
        let explosionAnchor = AnchorEntity(world: contactPoint)
        explosionAnchor.addChild(sphere)
        arView.scene.addAnchor(explosionAnchor)
        // Auto-remove after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            explosionAnchor.removeFromParent()
        }
    }
    
    func moveShips(placed: Bool) {
        // Skip distance culling for now - update all ships
        guard !ships.isEmpty else {
            print("❌ No ships to move")
            return
        }
        print("🚢 Moving \(ships.count) ships, placed: \(placed)")
        var perceivedCenter = SIMD3<Float>(0, 0, 0)
        var perceivedVelocity = SIMD3<Float>(0, 0, 0)
        for otherShip in ships {
            perceivedCenter = perceivedCenter + otherShip.entity.transform.translation
            perceivedVelocity = perceivedVelocity + otherShip.velocity
        }
        // Update all ships
        ships.forEach { ship in
            ship.updateShipPosition(
                perceivedCenter: perceivedCenter,
                perceivedVelocity: perceivedVelocity,
                otherShips: ships,
                obstacles: helicopterEntity != nil ? [helicopterEntity!] : []
            )
        }
        
        // Proper ship attack timing - balanced and controlled
        if placed {
            let currentTime = CACurrentMediaTime()
            
            // Set game start time on first placement
            if gameStartTime == 0 {
                gameStartTime = currentTime
                print("🚢 Game started - ships will begin attacking in \(attackDelay) seconds")
            }
            
            // Check if enough time has passed since game start and last attack
            let timeSinceGameStart = currentTime - gameStartTime
            let timeSinceLastAttack = currentTime - lastAttackTime
            
            if timeSinceGameStart >= attackDelay && timeSinceLastAttack >= attackCooldown {
                // Only one random ship attacks per cooldown period
                let availableShips = ships.filter { !$0.isDestroyed }
                if !availableShips.isEmpty, let helicopterEntity = helicopterEntity {
                    let attackingShip = availableShips.randomElement()!
                    print("🚢 Ship \(attackingShip.num ?? 0) attacking helicopter")
                    attackingShip.attack(target: helicopterEntity)
                    lastAttackTime = currentTime
                }
            }
        }
    }
    
    // MARK: - Network Synchronization Methods
    
    func updateShipsFromNetwork(_ shipData: [ShipSyncData]) {
        for data in shipData {
            if let ship = ships.first(where: { $0.id == data.shipId }) {
                ship.entity.transform.translation = data.position
                ship.entity.transform.rotation = data.rotation
                ship.velocity = data.velocity
                ship.isDestroyed = data.isDestroyed
                ship.targeted = data.targeted
            }
        }
    }
    
    func destroyShip(withId shipId: String) {
        if let ship = ships.first(where: { $0.id == shipId }) {
            ship.isDestroyed = true
            ship.cleanup()
        }
    }
    
    func setShipTargeted(shipId: String, targeted: Bool) {
        if let ship = ships.first(where: { $0.id == shipId }) {
            ship.targeted = targeted
            if targeted {
                // Add target indicator (inline implementation)
                let square = ReticleEntity()
                ship.square = square
                ship.targetAdded = true
                square.transform.translation = ship.entity.transform.translation
                
                if let parent = ship.entity.parent {
                    parent.addChild(square)
                }
                
                targetIndicators[ship.id] = square
            } else {
                ship.square?.removeFromParent()
                ship.square = nil
                ship.targetAdded = false
                targetIndicators.removeValue(forKey: ship.id)
            }
        }
    }
    
    // MARK: - Game Management
    
    func resetAttackTiming() {
        lastAttackTime = 0
        gameStartTime = 0
        attack = false
        print("🚢 Attack timing reset")
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        for indicator in targetIndicators.values {
            indicator.removeFromParent()
        }
        targetIndicators.removeAll()
        
        for ship in ships {
            ship.cleanup()
        }
        ships.removeAll()
        
        // Reset attack timing on cleanup
        resetAttackTiming()
    }
}
