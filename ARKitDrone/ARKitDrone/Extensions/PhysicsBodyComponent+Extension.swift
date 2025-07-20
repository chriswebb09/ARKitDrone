//
//  PhysicsBodyComponent+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import simd

/// This extension provides compatibility shims for legacy code
extension PhysicsBodyComponent {
    
    /// Linear velocity as SIMD3<Float> (compatibility shim)
    var simdLinearVelocity: SIMD3<Float> {
        get { return SIMD3<Float>.zero }
        set { /* No-op for compatibility */ }
    }
    
    /// Angular velocity as SIMD3<Float> (compatibility shim)
    var simdAngularVelocity: SIMD3<Float> {
        get { return SIMD3<Float>.zero }
        set { /* No-op for compatibility */ }
    }
    
    /// Apply force as SIMD3<Float> (compatibility shim)
    /// use transform-based movement instead
    mutating func applyForce(_ force: SIMD3<Float>, asImpulse impulse: Bool = false) {
        // RealityKit uses different physics paradigm
    }
    
    /// Apply torque as SIMD3<Float> (compatibility shim)
    /// use transform-based rotation instead
    mutating func applyTorque(_ torque: SIMD3<Float>, asImpulse impulse: Bool = false) {
        // RealityKit uses different physics paradigm
    }
    
    /// Apply force at specific position (compatibility shim)
    /// use transform-based movement instead
    mutating func applyForce(_ force: SIMD3<Float>, at position: SIMD3<Float>, asImpulse impulse: Bool = false) {
        // RealityKit uses different physics paradigm
    }
}

/// Entity extensions for physics convenience
extension Entity {
    
    /// Get physics body component safely
    var physicsBody: PhysicsBodyComponent? {
        get {
            return components[PhysicsBodyComponent.self]
        }
        set {
            if let newValue = newValue {
                components.set(newValue)
            } else {
                components.remove(PhysicsBodyComponent.self)
            }
        }
    }
    
    /// Check if entity has physics
    var hasPhysics: Bool {
        return components.has(PhysicsBodyComponent.self)
    }
    
    /// Apply physics force to entity
    func applyPhysicsForce(_ force: SIMD3<Float>, asImpulse impulse: Bool = false) {
        guard var physics = physicsBody else { return }
        physics.applyForce(force, asImpulse: impulse)
        components.set(physics)
    }
    
    /// Apply physics torque to entity
    func applyPhysicsTorque(_ torque: SIMD3<Float>, asImpulse impulse: Bool = false) {
        guard var physics = physicsBody else { return }
        physics.applyTorque(torque, asImpulse: impulse)
        components.set(physics)
    }
    
    /// Get/set linear velocity
    var linearVelocity: SIMD3<Float> {
        get {
            return SIMD3<Float>.zero
        }
        set {
            // Use transform-based movement instead
        }
    }
    
    /// Get/set angular velocity
    var angularVelocity: SIMD3<Float> {
        get {
            return SIMD3<Float>.zero
        }
        set {
            // RealityKit doesn't allow direct angular velocity setting
        }
    }
}

/// Physics material extensions 
extension PhysicsMaterialResource {
    
    /// Create material with restitution and friction
    static func create(restitution: Float = 0.5, friction: Float = 0.5) -> PhysicsMaterialResource {
        return PhysicsMaterialResource.generate(
            friction: friction,
            restitution: restitution
        )
    }
    
    /// High bounce material
    static var highBounce: PhysicsMaterialResource {
        return create(restitution: 0.9, friction: 0.1)
    }
    
    /// No bounce material
    static var noBounce: PhysicsMaterialResource {
        return create(restitution: 0.0, friction: 0.8)
    }
    
    /// Ice-like material (low friction)
    static var ice: PhysicsMaterialResource {
        return create(restitution: 0.1, friction: 0.05)
    }
    
    /// Rubber-like material
    static var rubber: PhysicsMaterialResource {
        return create(restitution: 0.8, friction: 0.9)
    }
}
