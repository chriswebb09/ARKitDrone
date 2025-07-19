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
class Ship: @unchecked Sendable {
    
    var entity: Entity
    var targeted: Bool = false
    var velocity: SIMD3<Float> = SIMD3<Float>(0.01, 0.01, 0.01)
    var prevDir: SIMD3<Float> = SIMD3<Float>(0, 1, 0)
    
    private static var shipRegistry: [Entity: Ship] = [:]
    
    var isDestroyed: Bool = false
    var square: TargetNode?
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
        let entityToRemove = entity
        Task { @MainActor in
            Ship.shipRegistry.removeValue(forKey: entityToRemove)
        }
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
        var rebound = SIMD3<Float>(0, 0, 0)
        let minBounds = SIMD3<Float>(-30, -30, -100)
        let maxBounds = SIMD3<Float>(50, 50, 50)
        let pos = ship.entity.transform.translation
        if pos.x < minBounds.x { rebound.x = 1 }
        if pos.x > maxBounds.x { rebound.x = -1 }
        if pos.y < minBounds.y { rebound.y = 1 }
        if pos.y > maxBounds.y { rebound.y = -1 }
        if pos.z < minBounds.z { rebound.z = 1 }
        if pos.z > maxBounds.z { rebound.z = -1 }
        return rebound
    }
    
    func limitVelocity(_ ship: Ship) {
        let mag = simd_length(ship.velocity)
        let limit: Float = 0.8
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
                if distance < 40 {
                    forceAway = forceAway - (otherShip.entity.transform.translation - ship.entity.transform.translation)
                }
            }
        }
        return forceAway
    }
    
    @MainActor
    func updateShipPosition(perceivedCenter: SIMD3<Float>, perceivedVelocity: SIMD3<Float>, otherShips: [Ship], obstacles: [Entity]) {
        var v1 = flyCenterOfMass(
            otherShips.count,
            perceivedCenter
        )
        var v2 = keepASmallDistance(
            self,
            ships: otherShips
        )
        var v3 = matchSpeedWithOtherShips(
            otherShips.count,
            perceivedVelocity
        )
        var v4 = boundPositions(self)
        
        v1 *= 0.1
        v2 *= 0.1
        v3 *= 0.1
        v4 *= 1.0
        
        velocity = velocity + v1 + v2 + v3 + v4
        limitVelocity(self)
        // Update position
        entity.transform.translation = entity.transform.translation + velocity
        // Update rotation to face movement direction
        if simd_length(velocity) > 0.001 {
            let direction = simd_normalize(velocity)
            entity.look(
                at: entity.transform.translation + direction,
                from: entity.transform.translation,
                relativeTo: nil
            )
        }
        // Update target square if present
        if targetAdded, let square = square {
            square.transform.translation = SIMD3<Float>(
                entity.transform.translation.x,
                entity.transform.translation.y,
                entity.transform.translation.z
            )
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
        let attackRange: Float = 50.0
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
                    _ = Timer.scheduledTimer(
                        withTimeInterval: 0.5,
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
            // Create missile entity
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
            // Add physics force simulation
            _ = direction * 1000
            // Add to scene (you'll need to pass the scene reference)
            // scene.addAnchor(AnchorEntity(world: missile.transform.translation))
        }
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
