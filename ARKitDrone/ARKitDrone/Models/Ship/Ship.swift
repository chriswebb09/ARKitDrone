//
//  Ship.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/11/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import simd
import UIKit

// MARK: - Ship Constants (Simplified)

private struct ShipConstants {
    static let maxVelocity: Float = 0.5
    static let separationDistance: Float = 5.0
    static let worldBounds: Float = 15.0
    static let forwardSpeed: Float = 0.015
}

@MainActor
class Ship: GameEntity {
    
    let entity: Entity
    let id: String
    var targeted: Bool = false
    var velocity: SIMD3<Float> = SIMD3<Float>(0.01, 0.01, 0.01)
    var isDestroyed: Bool = false
    var square: ReticleEntity?
    var targetAdded = false
    var fired = false
    var num: Int?
    
    // Ship registry for lookups
    nonisolated private static let registryManager = ShipRegistryManager()
    
    // Simple health system
    private(set) var maxHealth: Int = 100
    private(set) var currentHealth: Int = 100
    private var healthBar: ModelEntity?
    
    init(entity: Entity, id: String? = nil) {
        self.entity = entity
        self.id = id ?? UUID().uuidString
        
        Ship.registryManager.register(entity: entity, ship: self)
        
        // Set entity name for collision detection
        self.entity.name = "Ship_\(self.id.prefix(8))"
        
        setupPhysics()
    }
    
    deinit {
        Ship.registryManager.unregister(entity: entity)
    }
    
    private func setupPhysics() {
        let physicsComponent = PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: 1.0),
            material: PhysicsMaterialResource.default,
            mode: .kinematic
        )
        entity.components.set(physicsComponent)
        let collisionComponent = CollisionComponent(
            shapes: [ShapeResource.generateBox(
                size: SIMD3<Float>(1, 1, 1)
            )]
        )
        entity.components.set(collisionComponent)
    }
    
    // MARK: - Movement (Simplified)
    
    /// Simple cohesion - move toward center of nearby ships
    func getCohesionForce(_ shipCount: Int, _ perceivedCenter: SIMD3<Float>) -> SIMD3<Float> {
        guard shipCount > 1 else { return SIMD3<Float>(0, 0, 0) }
        let centerOfMass = perceivedCenter / Float(shipCount - 1)
        return (centerOfMass - entity.transform.translation) * 0.003
    }
    
    /// Simple alignment - match velocity with nearby ships  
    func getAlignmentForce(_ shipCount: Int, _ perceivedVelocity: SIMD3<Float>) -> SIMD3<Float> {
        guard shipCount > 1 else { return SIMD3<Float>(0, 0, 0) }
        let averageVelocity = perceivedVelocity / Float(shipCount - 1)
        return (averageVelocity - velocity) * 0.001
    }
    
    /// Simple boundary avoidance
    func getBoundaryForce() -> SIMD3<Float> {
        let pos = entity.transform.translation
        var force = SIMD3<Float>(0, 0, 0)
        
        // Simple boundary avoidance
        if abs(pos.x) > ShipConstants.worldBounds { force.x = -pos.x * 0.1 }
        if abs(pos.y) > ShipConstants.worldBounds { force.y = -pos.y * 0.1 }
        if abs(pos.z) > ShipConstants.worldBounds { force.z = -pos.z * 0.1 }
        
        return force
    }
    
    /// Simple velocity limiting
    func limitVelocity() {
        // Check for invalid values first
        if velocity.x.isNaN || velocity.y.isNaN || velocity.z.isNaN ||
           velocity.x.isInfinite || velocity.y.isInfinite || velocity.z.isInfinite {
            // Reset to zero if any component is invalid
            velocity = SIMD3<Float>(0, 0, 0)
            return
        }
        
        let magnitude = simd_length(velocity)
        if magnitude.isNaN || magnitude.isInfinite {
            // Reset to zero if magnitude is invalid
            velocity = SIMD3<Float>(0, 0, 0)
            return
        }
        
        if magnitude > ShipConstants.maxVelocity {
            velocity = (velocity / magnitude) * ShipConstants.maxVelocity
        }
    }
    
    nonisolated static func getShip(from entity: Entity) -> Ship? {
        return registryManager.getShip(for: entity)
    }
    
    /// Simple separation - avoid other ships
    func getSeparationForce(from otherShips: [Ship]) -> SIMD3<Float> {
        var separationForce = SIMD3<Float>(0, 0, 0)
        
        for otherShip in otherShips {
            guard entity != otherShip.entity else { continue }
            
            let distance = simd_distance(
                otherShip.entity.transform.translation,
                entity.transform.translation
            )
            
            if distance < ShipConstants.separationDistance && distance > 0 {
                let direction = entity.transform.translation - otherShip.entity.transform.translation
                let normalizedDirection = simd_normalize(direction)
                separationForce += normalizedDirection * 0.008
            }
        }
        
        return separationForce
    }
    
    /// Simple ship movement update (simplified)
    @MainActor
    func updateShipPosition(perceivedCenter: SIMD3<Float>, perceivedVelocity: SIMD3<Float>, otherShips: [Ship], obstacles: [Entity]) {
        // Calculate simple forces
        let cohesion = getCohesionForce(otherShips.count, perceivedCenter)
        let alignment = getAlignmentForce(otherShips.count, perceivedVelocity)
        let separation = getSeparationForce(from: otherShips)
        let boundary = getBoundaryForce()
        let forward = SIMD3<Float>(0, 0, ShipConstants.forwardSpeed)
        
        // Combine all forces
        let totalForce = cohesion + alignment + separation + boundary + forward
        
        // Update velocity and position
        velocity += totalForce
        limitVelocity()
        
        // Update position
        entity.transform.translation += velocity
        
        // Simple rotation toward velocity direction
        if simd_length(velocity) > 0.01 {
            let targetRotation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: simd_normalize(velocity))
            entity.transform.rotation = simd_slerp(entity.transform.rotation, targetRotation, 0.1)
        }
        
        // Update target square if present
        updateTargetSquarePosition()
    }
    
    // MARK: - Helper Methods
    
    private func updateTargetSquarePosition() {
        if targetAdded, let square = square {
            square.transform.translation = entity.transform.translation
        }
    }
    
}

extension Ship {
    
    @MainActor
    func attack(target: Entity) {
        let distanceToTarget = simd_distance(
            entity.transform.translation,
            target.transform.translation
        )
        let attackRange: Float = 15.0 // Reduced range for more balanced gameplay
        
        // Look at target
        entity.look(
            at: target.transform.translation,
            from: entity.transform.translation,
            relativeTo: nil
        )
        
        if distanceToTarget <= attackRange {
            if !isDestroyed {
                if !fired {
                    fired = true
                    self.fireAt(target)
                    
                    // Longer cooldown for ship attacks
                    _ = Timer.scheduledTimer(
                        withTimeInterval: 2.0, // 2 second cooldown
                        repeats: false
                    ) { [weak self] timer in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.fired = false
                        }
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    private func fireAt(_ target: Entity) {
        Task { @MainActor in
            
            // Deal direct damage to helicopter
            if let helicopterObject = findHelicopterObject(from: target) {
                let damage: Float = Float.random(in: 8.0...15.0) // Random damage between 8-15
                helicopterObject.takeDamage(damage, from: "ship-attack")
            } else {
            }
            
            // Create visual missile effect (optional)
            let missile = createMissile()
            missile.transform.translation = self.entity.transform.translation
            let targetPos = target.transform.translation
            let currentPos = missile.transform.translation
            let direction = simd_normalize(targetPos - currentPos)
            missile.look(
                at: targetPos,
                from: currentPos,
                relativeTo: nil
            )
            
            // Create temporary anchor for visual effect
            let missileAnchor = AnchorEntity(world: currentPos)
            missileAnchor.addChild(missile)
            
            // Add to scene temporarily (you'll need scene reference)
            if let scene = target.scene {
                scene.addAnchor(missileAnchor)
                
                // Remove missile visual after short time
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    missileAnchor.removeFromParent()
                }
            }
        }
    }
    
    private func findHelicopterObject(from entity: Entity) -> HelicopterObject? {
        // Search for helicopter object through GameManager
        // This is a simplified approach - in practice you'd pass references
        let players = [UserDefaults.standard.myself] // Add other players if multiplayer
        
        // For now, we'll use notification to deal damage since we don't have direct access
        // Post notification that helicopter should take damage
        NotificationCenter.default.post(
            name: NSNotification.Name("HelicopterTakeDamage"),
            object: nil,
            userInfo: ["damage": 12.0, "source": "ship-attack"]  // Fixed damage for consistency
        )
        
        return nil // Will be handled by notification
    }
    
    private func createMissile() -> Entity {
        let missile = Entity()
        missile.name = "Missile"
        // Create missile geometry
        let geometry = MeshResource.generateCylinder(
            height: 0.4,
            radius: 0.06
        )
        var material = UnlitMaterial()
        material.color = .init(tint: .red)
        missile.components.set(
            ModelComponent(
                mesh: geometry,
                materials: [material]
            )
        )
        // Add physics
        let physicsComponent = PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: 0.1),
            material: PhysicsMaterialResource.default,
            mode: .dynamic
        )
        missile.components.set(physicsComponent)
        let collisionComponent = CollisionComponent(
            shapes: [ShapeResource.generateCapsule(
                height: 0.4,
                radius: 0.06
            )]
        )
        missile.components.set(collisionComponent)
        return missile
    }
    
    nonisolated static func removeShip(conditionalShipEntity: Entity) {
        if let ship = Ship.getShip(from: conditionalShipEntity) {
            Task { @MainActor in
                ship.isDestroyed = true
                ship.square?.isEnabled = false
                ship.square?.removeFromParent()
                ship.entity.isEnabled = false
                ship.entity.removeFromParent()
            }
        }
    }
    
    @MainActor
    func removeShip() {
        isDestroyed = true
        square?.isEnabled = false
        square?.removeFromParent()
        entity.isEnabled = false
        entity.removeFromParent()
    }
    
    // MARK: - GameEntity Protocol Implementation
    
    func update(deltaTime: TimeInterval) {
        // Ships update their movement and behavior
        // This will be called by EntityManager during update cycles
        if !isDestroyed {
            // Move ship logic could be moved here from ShipManager
            // For now, keep existing movement in ShipManager
        }
    }
    
    @MainActor
    func cleanup() {
        // Enhanced cleanup for ships
        guard !isDestroyed else { return } // Prevent double cleanup
        isDestroyed = true
        
        // Clean up targeting reticle safely
        if let square = square {
            square.isEnabled = false
            if square.parent != nil {
                square.removeFromParent()
            }
            self.square = nil
        }
        
        // Clean up entity safely
        if entity.parent != nil {
            entity.isEnabled = false
            entity.removeFromParent()
        }
        
        // Remove from static registry (legacy support during transition)
        Ship.registryManager.unregister(entity: entity)
    }
    
    @MainActor
    func onDestroy() {
        // Called when ship is destroyed (e.g., hit by missile)
        cleanup()
    }
    
    // MARK: - Health System
    
    private func createHealthBar() {
        Task { @MainActor in
            // Create a simple health bar above the ship
            let barWidth: Float = 1.0
            let barHeight: Float = 0.1
            let barThickness: Float = 0.02
            
            let mesh = MeshResource.generateBox(width: barWidth, height: barHeight, depth: barThickness)
            var material = UnlitMaterial()
            material.color = .init(tint: .green)
            
            healthBar = ModelEntity(mesh: mesh, materials: [material])
            healthBar?.transform.translation = SIMD3<Float>(0, 2.0, 0) // Above ship
            
            if let healthBar = healthBar {
                entity.addChild(healthBar)
            }
        }
    }
    
    func takeDamage(_ damage: Int) {
        guard !isDestroyed else { return }
        
        currentHealth = max(0, currentHealth - damage)
        
        // Update health bar visual
        updateHealthBar()
        
        // Check if ship is destroyed
        if currentHealth <= 0 {
            isDestroyed = true
            onDestroy()
        }
    }
    
    private func updateHealthBar() {
        Task { @MainActor in
            guard let healthBar = healthBar else { return }
            
            let healthPercentage = Float(currentHealth) / Float(maxHealth)
            
            // Update color based on health
            var material = UnlitMaterial()
            if healthPercentage > 0.6 {
                material.color = .init(tint: .green)
            } else if healthPercentage > 0.3 {
                material.color = .init(tint: .yellow)
            } else {
                material.color = .init(tint: .red)
            }
            
            // Update width based on health percentage
            let barWidth = healthPercentage * 1.0
            let mesh = MeshResource.generateBox(width: barWidth, height: 0.1, depth: 0.02)
            healthBar.model?.mesh = mesh
            healthBar.model?.materials = [material]
        }
    }
    
    func getHealthPercentage() -> Float {
        return Float(currentHealth) / Float(maxHealth)
    }
    
    func isLowHealth() -> Bool {
        return getHealthPercentage() < 0.3
    }
    
}

// MARK: - Thread-safe Ship Registry Manager

private class ShipRegistryManager: @unchecked Sendable {
    private var registry: [Entity: Ship] = [:]
    private let lock = NSLock()
    
    nonisolated func register(entity: Entity, ship: Ship) {
        lock.lock()
        defer { lock.unlock() }
        registry[entity] = ship
    }
    
    nonisolated func unregister(entity: Entity) {
        lock.lock()
        defer { lock.unlock() }
        registry.removeValue(forKey: entity)
    }
    
    nonisolated func getShip(for entity: Entity) -> Ship? {
        lock.lock()
        defer { lock.unlock() }
        return registry[entity]
    }
}
