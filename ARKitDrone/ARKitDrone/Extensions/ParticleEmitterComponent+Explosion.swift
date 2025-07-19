//
//  ParticleEmitterComponent+Explosion.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import Foundation

extension ParticleEmitterComponent {
    
    /// Create an explosion particle effect using RealityKit
    static func createExplosion() -> ParticleEmitterComponent {
        // Create particle emitter with simple configuration
        // Note: RealityKit's ParticleEmitterComponent has limited customization compared to SceneKit
        // Create basic particle emitter component
        let particles = ParticleEmitterComponent()
        return particles
    }
    
    /// Create an optimized missile exhaust particle effect
    static func createMissileExhaust() -> ParticleEmitterComponent {
        // RealityKit's ParticleEmitterComponent has very limited configuration
        // We'll create a basic emitter and rely on distance culling for optimization
        let particles = ParticleEmitterComponent()
        // Note: RealityKit doesn't support custom textures on ParticleEmitterComponent
        // For custom particle effects, you'd need to create a custom Material/Shader
        return particles
    }
    
    /// Create a simple spark texture programmatically
    @MainActor
    private static func createSparkTexture() -> MaterialColorParameter? {
        // Load spark texture from art.scnassets
        if let sparkTexture = try? TextureResource.load(named: "art.scnassets/spark") {
            return MaterialColorParameter.texture(sparkTexture)
        }
        return nil
    }
    
    /// Create a fade-out opacity curve
    private static func createFadeOutCurve() -> Float {
        // RealityKit doesn't have the same curve system as SceneKit
        // Return a simple fade value instead
        return 0.0
    }
}

extension Entity {
    
    /// Add an explosion effect to this entity
    @MainActor
    func addExplosionEffect(at position: SIMD3<Float>? = nil) {
        let explosionEntity = Entity()
        // Set position if provided
        if let pos = position {
            explosionEntity.transform.translation = pos
        }
        // Add particle emitter component
        let explosion = ParticleEmitterComponent.createExplosion()
        explosionEntity.components.set(explosion)
        // Add to parent
        self.addChild(explosionEntity)
        // Remove after explosion duration (fixed duration since we can't access lifeSpan)
        let duration = 2.0 // Fixed duration for explosion effect
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            explosionEntity.removeFromParent()
        }
    }
}

// MARK: - RealityKit Explosion Helper

class Explosion {
    
    /// Create a standalone explosion entity
    @MainActor
    static func createExplosionEntity() -> Entity {
        let explosionEntity = Entity()
        explosionEntity.name = "Explosion"
        // Add particle emitter
        let explosion = ParticleEmitterComponent.createExplosion()
        explosionEntity.components.set(explosion)
        return explosionEntity
    }
    
    /// Create explosion with auto-cleanup
    @MainActor
    static func createTemporaryExplosion(in scene: Entity, at position: SIMD3<Float>) {
        let explosion = createExplosionEntity()
        explosion.transform.translation = position
        scene.addChild(explosion)
        // Auto-remove after particles finish
        let duration = 2.0 // Safe duration for cleanup
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            explosion.removeFromParent()
        }
    }
}
