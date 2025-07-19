//
//  Shell.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/31/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import ARKit
import simd
import UIKit

@MainActor
class Shell {
    
    var entity: Entity

    init(_ entity: Entity) {
        self.entity = entity
    }

    static func createShell() async -> Shell {
        // Create sphere mesh
        let geometry = MeshResource.generateSphere(radius: 0.005)
        // Create red material
        let material = SimpleMaterial.create(color: .red)
        // Create entity with model component
        let shellEntity = Entity()
        shellEntity.components.set(
            ModelComponent(
                mesh: geometry,
                materials: [material]
            )
        )
        // Add physics body
        let physicsComponent = PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: 0.1),
            material: .default,
            mode: .dynamic
        )
        shellEntity.components.set(physicsComponent)
        // Add collision component for sphere
        let collisionComponent = CollisionComponent(
            shapes: [ShapeResource.generateSphere(radius: 0.005)]
        )
        shellEntity.components.set(collisionComponent)
        return Shell(shellEntity)
    }

    func launchProjectile(position: SIMD3<Float>, force: SIMD3<Float>, name: String) {
        entity.name = name
        // Set initial position
        entity.transform.translation = position
        // Apply force using RealityKit physics
        if let physicsBody = entity.components[PhysicsBodyComponent.self] {
            let mass = physicsBody.massProperties.mass
            _ = force / mass
            var updatedPhysics = physicsBody
            updatedPhysics.massProperties = PhysicsMassProperties(
                mass: mass,
                inertia: physicsBody.massProperties.inertia,
                centerOfMass: physicsBody.massProperties.centerOfMass
            )
            entity.components.set(updatedPhysics)
            // TODO: Apply velocity via custom motion system if needed
        }
    }

    // Convenience method with individual force components
    func launchProjectile(position: SIMD3<Float>, x: Float, y: Float, z: Float, name: String) {
        let force = SIMD3<Float>(x, y, z)
        launchProjectile(
            position: position,
            force: force,
            name: name
        )
    }
}
