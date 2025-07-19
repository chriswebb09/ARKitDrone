//
//  Missile.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import simd
import UIKit

// MARK: - Missile
@MainActor
class Missile {
    
    var entity: Entity
    var particleEntity: Entity?
    var fired: Bool = false
    var exhaustEntity: Entity?
    var hit: Bool = false
    var id: String
    var num: Int = -1
    
    private static var missileRegistry: [Entity: Missile] = [:]
    private static let registryQueue = DispatchQueue(
        label: "missile.registry",
        attributes: .concurrent
    )
    private static let maxParticleDistance: Float = 50.0  // Max distance for particles
    private static let maxActiveParticles: Int = 5  // Limit active particle systems
    
    init() {
        self.entity = Entity()
        self.id = UUID().uuidString
    }
    
    func setupEntity(entity: Entity, number: Int) {
        self.entity = entity
        self.num = number
        entity.name = "Missile \(num)"
        // Don't add physics body - it might be creating visual debug shapes
        // The missile will be handled by distance-based collision detection
        // Don't add visible collision component - let the missile model handle its own collision
        // The collision detection will be handled by distance checking in MissileManager
        setupParticleSystem()
        // Remove async dispatch to prevent retain cycles
        Missile.missileRegistry[entity] = self
    }
    
    deinit {
        // Remove async dispatch to prevent retain cycles
        let entity = self.entity
        Task { @MainActor in
            Missile.missileRegistry.removeValue(forKey: entity)
        }
    }
    
    private func setupParticleSystem() {
        // Create particle entity for exhaust
        let particleEntity = Entity()
        particleEntity.name = "MissileExhaust"
        // Position exhaust at the back/end of the missile
        // Assuming missile points forward in +Z direction, exhaust goes at -Z
        particleEntity.transform.translation = SIMD3<Float>(0, 0, -0.5)
        // Add optimized particle emitter component for missile exhaust
        let particles = ParticleEmitterComponent.createMissileExhaust()
        particleEntity.components.set(particles)
        // Initially disable particles
        particleEntity.isEnabled = false
        entity.addChild(particleEntity)
        self.particleEntity = particleEntity
    }
    
    func fire(direction: SIMD3<Float>) {
        fireToPosition(entity.transform.translation)
    }
    
    func fireToPosition(_ targetPosition: SIMD3<Float>) {
        print("Missile \(num) firing to position \(targetPosition)")
        guard !fired else { return }
        fired = true
        particleEntity?.isEnabled = true
        let start = entity.transform.translation
        let direction = simd_normalize(targetPosition - start)
        // Rotate missile to face direction
        entity.transform.rotation = simd_quatf(
            from: SIMD3<Float>(0, 0, 1),
            to: direction
        )
        let distance = simd_length(targetPosition - start)
        let speed: Float = 10  // Reduced from 30 to 10 for slower motion
        let duration = TimeInterval(distance / speed)
        let moveAnimation = FromToByAnimation<Transform>(
            name: "missileFlight",
            from: Transform(
                rotation: entity.transform.rotation,
                translation: start
            ),
            to: Transform(
                rotation: entity.transform.rotation,
                translation: targetPosition
            ),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )
        if let animationResource = try? AnimationResource.generate(with: moveAnimation) {
            entity.playAnimation(animationResource)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.cleanup()
            }
        }
    }
    
    func fire(x: Float, y: Float) {
        let direction = SIMD3<Float>(x, y, -1.0)
        fire(direction: simd_normalize(direction))
    }
    
    private func cleanup() {
        particleEntity?.isEnabled = false
        
        // Remove after brief delay to let particles fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.entity.removeFromParent()
        }
    }
    
    func addCollision() {
        // Collision is already set up in setupEntity, but we can modify it here if needed
        let physicsComponent = PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: 0.5),
            material: PhysicsMaterialResource.default,
            mode: .kinematic
        )
        entity.components.set(physicsComponent)
    }
    
    static func getMissile(from entity: Entity) -> Missile? {
        return missileRegistry[entity]
    }
    
    /// Update particle visibility based on distance from camera
    func updateParticleVisibility(cameraPosition: SIMD3<Float>) {
        guard let particleEntity = particleEntity else { return }
        let distance = simd_length(entity.transform.translation - cameraPosition)
        let shouldShowParticles = fired && distance < Self.maxParticleDistance
        // Only enable particles if missile is fired and within range
        if particleEntity.isEnabled != shouldShowParticles {
            particleEntity.isEnabled = shouldShowParticles
        }
    }
    
    /// Optimize all missile particles globally
    static func optimizeAllParticles(cameraPosition: SIMD3<Float>) {
        // Get all active missiles with particles
        var particleMissiles: [(distance: Float, missile: Missile)] = []
        for (_, missile) in missileRegistry {
            if missile.fired && missile.particleEntity != nil {
                let distance = simd_length(missile.entity.transform.translation - cameraPosition)
                particleMissiles.append((distance: distance, missile: missile))
            }
        }
        // Sort by distance (closest first)
        particleMissiles.sort { $0.distance < $1.distance }
        // Enable particles for closest missiles only
        for (index, item) in particleMissiles.enumerated() {
            let shouldEnable = index < maxActiveParticles && item.distance < maxParticleDistance
            item.missile.particleEntity?.isEnabled = shouldEnable
        }
    }
}
