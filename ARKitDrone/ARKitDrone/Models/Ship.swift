//
//  Ship.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/11/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import simd
import UIKit

@MainActor
class Ship {
    
    var entity: Entity
    var targeted: Bool = false
    var velocity: SIMD3<Float> = SIMD3<Float>(0.01, 0.01, 0.01)
    var prevDir: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    var smoothedVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 1)  // Smoothed velocity for rotation
    
    @MainActor private static var shipRegistry: [Entity: Ship] = [:]
    
    var isDestroyed: Bool = false
    var square: ReticleEntity?
    var targetAdded = false
    var fired = false
    var id: String
    var num: Int?
    
    init(entity: Entity) {
        self.entity = entity
        self.id = UUID().uuidString
        Ship.shipRegistry[entity] = self
        setupPhysics()
    }
    
    deinit {
        // Registry cleanup will happen through explicit removeShip() calls
        // Avoid async cleanup in deinit to prevent race conditions
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
    
    @MainActor
    func flyCenterOfMass(_ shipCount: Int, _ perceivedCenter: SIMD3<Float>) -> SIMD3<Float> {
        let averagePerceivedCenter = perceivedCenter / Float(shipCount - 1)
        return (averagePerceivedCenter - entity.transform.translation) / 100
    }
    
    func matchSpeedWithOtherShips(_ shipCount: Int, _ perceivedVelocity: SIMD3<Float>) -> SIMD3<Float> {
        let averagePerceivedVelocity = perceivedVelocity / Float(shipCount - 1)
        return (averagePerceivedVelocity - velocity)
    }
    
    @MainActor
    func boundPositions(_ ship: Ship) -> SIMD3<Float> {
        let pos = ship.entity.transform.translation
        let minBounds = SIMD3<Float>(-15, -15, -25)
        let maxBounds = SIMD3<Float>(15, 15, 25)
        let boundaryBuffer: Float = 5.0  // Larger buffer for smoother avoidance
        
        var avoidanceForce = SIMD3<Float>(0, 0, 0)
        
        // Smoother boundary avoidance with quadratic falloff
        if pos.x < minBounds.x + boundaryBuffer {
            let distance = pos.x - minBounds.x
            let normalizedDistance = max(0, distance / boundaryBuffer)
            let strength = (1.0 - normalizedDistance * normalizedDistance) * 0.5  // Gentler force
            avoidanceForce.x += strength
        }
        if pos.x > maxBounds.x - boundaryBuffer {
            let distance = maxBounds.x - pos.x
            let normalizedDistance = max(0, distance / boundaryBuffer)
            let strength = (1.0 - normalizedDistance * normalizedDistance) * 0.5
            avoidanceForce.x -= strength
        }
        if pos.y < minBounds.y + boundaryBuffer {
            let distance = pos.y - minBounds.y
            let normalizedDistance = max(0, distance / boundaryBuffer)
            let strength = (1.0 - normalizedDistance * normalizedDistance) * 0.5
            avoidanceForce.y += strength
        }
        if pos.y > maxBounds.y - boundaryBuffer {
            let distance = maxBounds.y - pos.y
            let normalizedDistance = max(0, distance / boundaryBuffer)
            let strength = (1.0 - normalizedDistance * normalizedDistance) * 0.5
            avoidanceForce.y -= strength
        }
        if pos.z < minBounds.z + boundaryBuffer {
            let distance = pos.z - minBounds.z
            let normalizedDistance = max(0, distance / boundaryBuffer)
            let strength = (1.0 - normalizedDistance * normalizedDistance) * 0.5
            avoidanceForce.z += strength
        }
        if pos.z > maxBounds.z - boundaryBuffer {
            let distance = maxBounds.z - pos.z
            let normalizedDistance = max(0, distance / boundaryBuffer)
            let strength = (1.0 - normalizedDistance * normalizedDistance) * 0.5
            avoidanceForce.z -= strength
        }
        
        return avoidanceForce
    }
    
    func limitVelocity(_ ship: Ship) {
        let mag = simd_length(ship.velocity)
        let limit: Float = 0.5
        if mag > limit {
            ship.velocity = (ship.velocity / mag) * limit
        }
    }
    
    @MainActor
    static func getShip(from entity: Entity) -> Ship? {
        return shipRegistry[entity]
    }
    
    func smoothForces(forces: SIMD3<Float>, factor: Float) -> SIMD3<Float> {
        return velocity + forces * factor
    }
    
    @MainActor
    func keepASmallDistance(_ ship: Ship, ships: [Ship]) -> SIMD3<Float> {
        var forceAway = SIMD3<Float>(0, 0, 0)
        for otherShip in ships {
            if ship.entity != otherShip.entity {
                let distance = simd_distance(
                    otherShip.entity.transform.translation,
                    ship.entity.transform.translation
                )
                if distance < 5 {
                    forceAway = forceAway - (otherShip.entity.transform.translation - ship.entity.transform.translation)
                }
            }
        }
        return forceAway
    }
    
    @MainActor
    func updateShipPosition(perceivedCenter: SIMD3<Float>, perceivedVelocity: SIMD3<Float>, otherShips: [Ship], obstacles: [Entity]) {
        // Fighter jet physics: add forward thrust in current direction
        let currentDirection = entity.transform.rotation.act(SIMD3<Float>(0, 0, 1))
        let forwardThrust: Float = 0.02  // Very gentle forward momentum for ultra-smooth movement
        
        // Calculate boids forces
        var v1 = flyCenterOfMass(otherShips.count, perceivedCenter)
        var v2 = keepASmallDistance(self, ships: otherShips)
        var v3 = matchSpeedWithOtherShips(otherShips.count, perceivedVelocity)
        var v4 = boundPositions(self)
        
        // Scale forces much more gently for ultra-smooth movement
        v1 *= 0.005  // Cohesion (halved again)
        v2 *= 0.01   // Separation (halved for much gentler avoidance)
        v3 *= 0.002  // Alignment (reduced further)
        v4 *= 0.3    // Boundary avoidance (much gentler)
        
        // Log force calculations every 60 frames
        let frameNumber = Int(CACurrentMediaTime() * 60) % 60
        if frameNumber == 0 {
            print("🛩️ Ship \(id.prefix(8)): Forces - cohesion:\(v1) separation:\(v2) alignment:\(v3) boundary:\(v4)")
        }
        
        // Apply forces and forward thrust with smoothing
        let oldVelocity = velocity
        let totalForce = v1 + v2 + v3 + v4 + (currentDirection * forwardThrust)
        
        // Much more aggressive smoothing to eliminate jerkiness
        let smoothingFactor: Float = 0.9  // Smooth out 90% of force changes
        let newVelocity = velocity * smoothingFactor + (velocity + totalForce) * (1.0 - smoothingFactor)
        velocity = newVelocity
        limitVelocity(self)
        
        // Log smoothing effects
        if frameNumber == 0 {
            let velocityChange = simd_length(newVelocity - oldVelocity)
            let forceStrength = simd_length(totalForce)
            print("📊 Ship \(id.prefix(8)): Smoothing - oldVel:\(simd_length(oldVelocity)) newVel:\(simd_length(newVelocity)) velChange:\(velocityChange) forceStr:\(forceStrength)")
        }
        
        // Update position
        entity.transform.translation = entity.transform.translation + velocity
        
        // Much more stable rotation system with hysteresis and damping
        if simd_length(velocity) > 0.02 {
            let targetDirection = simd_normalize(velocity)
            let currentForward = entity.transform.rotation.act(SIMD3<Float>(0, 0, 1))
            
            // Smooth the target direction to reduce oscillation
            smoothedVelocity = smoothedVelocity * 0.9 + velocity * 0.1
            let smoothedTargetDirection = simd_normalize(smoothedVelocity)
            
            // Much stricter rotation criteria for ultra-smooth movement
            let alignment = simd_dot(currentForward, smoothedTargetDirection)
            let velocityChange = simd_length(velocity - oldVelocity)
            
            // Only rotate if direction change is VERY significant (> 45 degrees) and very stable
            if alignment < 0.7 && velocityChange < 0.02 {  // ~45 degrees, very stable velocity
                let oldRotation = entity.transform.rotation
                // Smoothly interpolate rotation instead of instant change
                let targetRotation = simd_quatf(from: SIMD3<Float>(0, 0, 1), to: smoothedTargetDirection)
                entity.transform.rotation = simd_slerp(oldRotation, targetRotation, 0.1)  // 10% interpolation
                
                let rotationChange = simd_length(oldRotation.vector - entity.transform.rotation.vector)
                if frameNumber == 0 {
                    print("🔄 Ship \(id.prefix(8)): Rotating - alignment:\(alignment) velChange:\(velocityChange) rotChange:\(rotationChange)")
                }
            } else if frameNumber == 0 {
                print("🚫 Ship \(id.prefix(8)): No rotation - alignment:\(alignment) velChange:\(velocityChange)")
            }
        }
        
        // Update target square if present
        if targetAdded, let square = square {
            square.transform.translation = entity.transform.translation
        }
    }
    
    @MainActor
    func updateShipPosition(target: SIMD3<Float>, otherShips: [Ship]) {
        let entities = otherShips.map { $0.entity }
        let perceivedCenter: SIMD3<Float>
        if otherShips.isEmpty {
            perceivedCenter = entity.transform.translation
        } else {
            let sumPositions = otherShips.reduce(SIMD3<Float>(0, 0, 0)) { (accumulated, ship) -> SIMD3<Float> in
                return accumulated + ship.entity.transform.translation
            }
            perceivedCenter = sumPositions / Float(otherShips.count)
        }
        let directionToTarget = simd_normalize(target - entity.transform.translation)
        let avoidCollisions = entities.reduce(SIMD3<Float>(0, 0, 0)) { (force, shipEntity) in
            let distance = simd_distance(entity.transform.translation, shipEntity.transform.translation)
            if distance < 14 {
                return force - simd_normalize(shipEntity.transform.translation - entity.transform.translation) * (1 / distance)
            }
            return force
        }
        let currentPos = entity.transform.translation
        let boundary = SIMD3<Float>(
            x: max(-10, min(10, currentPos.x)),
            y: max(-10, min(10, currentPos.y)),
            z: max(-10, min(10, currentPos.z))
        ) - currentPos
        let cohesion = (perceivedCenter - entity.transform.translation) * 0.1
        let separation = avoidCollisions * 0.1
        let alignment = directionToTarget * 0.2
        let newVelocity = cohesion + separation + alignment + boundary
        let speedLimit: Float = 0.4
        let speed = simd_length(newVelocity)
        velocity = (speed > speedLimit) ? simd_normalize(newVelocity) * speedLimit : newVelocity
        entity.transform.translation += velocity
        // Update target square
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
                    print("🎯 Ship \(id.prefix(8)) attacking helicopter at distance \(distanceToTarget)")
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
            print("🚢 Ship \(id.prefix(8)) firing at helicopter")
            
            // Deal direct damage to helicopter
            if let helicopterObject = findHelicopterObject(from: target) {
                let damage: Float = Float.random(in: 8.0...15.0) // Random damage between 8-15
                helicopterObject.takeDamage(damage, from: "ship-attack")
                print("💥 Ship dealt \(damage) damage to helicopter")
            } else {
                print("⚠️ Could not find helicopter object to damage")
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
            userInfo: ["damage": Float.random(in: 8.0...15.0), "source": "ship-attack"]
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
    
    @MainActor
    static func removeShip(conditionalShipEntity: Entity) {
        if let ship = Ship.getShip(
            from: conditionalShipEntity
        ) {
            ship.isDestroyed = true
            ship.square?.isEnabled = false
            ship.square?.removeFromParent()
            ship.entity.isEnabled = false
            ship.entity.removeFromParent()
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
}
