//
//  Entity+RealityKit.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import UIKit

extension Entity {
    /// Create Entity with specific mesh and materials
    @MainActor
    static func createWithMesh(_ meshResource: MeshResource, materials: [Material] = [SimpleMaterial.create(color: .white)]) -> Entity {
        let entity = Entity()
        entity.components.set(ModelComponent(mesh: meshResource, materials: materials))
        return entity
    }
    
    /// Create Entity with physics
    @MainActor
    static func createWithPhysics(mesh: MeshResource, materials: [Material], physicsMode: PhysicsBodyMode = .dynamic, mass: Float = 1.0) -> Entity {
        let entity = Entity.createWithMesh(mesh, materials: materials)
        let shape = ShapeResource.generateConvex(from: mesh)
        let physicsComponent = PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: mass),
            material: PhysicsMaterialResource.default,
            mode: physicsMode
        )
        entity.components.set(physicsComponent)
        let collisionComponent = CollisionComponent(shapes: [shape])
        entity.components.set(collisionComponent)
        return entity
    }
    
    /// Create a simple box entity
    @MainActor
    static func createBox(size: SIMD3<Float>, color: UIColor = .white, withPhysics: Bool = false, physicsMode: PhysicsBodyMode = .dynamic) -> Entity {
        let mesh = MeshResource.generateBox(size: size)
        let material = SimpleMaterial.create(color: color)
        if withPhysics {
            return Entity.createWithPhysics(
                mesh: mesh,
                materials: [material],
                physicsMode: physicsMode
            )
        } else {
            return Entity.createWithMesh(
                mesh,
                materials: [material]
            )
        }
    }
    
    /// Create a simple sphere entity
    @MainActor
    static func createSphere(radius: Float, color: UIColor = .white, withPhysics: Bool = false, physicsMode: PhysicsBodyMode = .dynamic) -> Entity {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial.create(color: color)
        if withPhysics {
            return Entity.createWithPhysics(
                mesh: mesh,
                materials: [material],
                physicsMode: physicsMode
            )
        } else {
            return Entity.createWithMesh(
                mesh,
                materials: [material]
            )
        }
    }
    
    /// Create a simple cylinder entity (using box as approximation since RealityKit has limited primitive shapes)
    @MainActor
    static func createCylinder(height: Float, radius: Float, color: UIColor = .white, withPhysics: Bool = false, physicsMode: PhysicsBodyMode = .dynamic) -> Entity {
        // Note: RealityKit only has generateBox, generateSphere, and generatePlane
        // Using a tall box as cylinder approximation, or load a USDZ cylinder model instead
        let size = SIMD3<Float>(radius * 2, height, radius * 2)
        let mesh = MeshResource.generateBox(size: size)
        let material = SimpleMaterial.create(color: color)
        if withPhysics {
            return Entity.createWithPhysics(
                mesh: mesh,
                materials: [material],
                physicsMode: physicsMode
            )
        } else {
            return Entity.createWithMesh(
                mesh,
                materials: [material]
            )
        }
    }
    
    /// Create a simple plane entity
    @MainActor
    static func createPlane(width: Float, height: Float, color: UIColor = .white, withPhysics: Bool = false, physicsMode: PhysicsBodyMode = .static) -> Entity {
        let mesh = MeshResource.generatePlane(
            width: width,
            height: height
        )
        let material = SimpleMaterial.create(color: color)
        if withPhysics {
            return Entity.createWithPhysics(
                mesh: mesh,
                materials: [material],
                physicsMode: physicsMode
            )
        } else {
            return Entity.createWithMesh(
                mesh,
                materials: [material]
            )
        }
    }
    
    /// Load Entity from USDZ file
    static func loadUSDZ(named filename: String, in bundle: Bundle = .main) async throws -> Entity {
        guard let url = bundle.url(forResource: filename, withExtension: "usdz") else {
            throw EntityError.missingFile(filename)
        }
        return try await Entity(contentsOf: url)
    }
    
    /// Load Entity from Reality file
    static func loadReality(named filename: String, in bundle: Bundle = .main) async throws -> Entity {
        guard let url = bundle.url(forResource: filename, withExtension: "reality") else {
            throw EntityError.missingFile(filename)
        }
        return try await Entity(contentsOf: url)
    }
    
    /// Load Entity from common file types
    static func load(named filename: String, withExtension ext: String = "usdz", in bundle: Bundle = .main) async throws -> Entity {
        guard let url = bundle.url(forResource: filename, withExtension: ext) else {
            throw EntityError.missingFile("\(filename).\(ext)")
        }
        return try await Entity(contentsOf: url)
    }
    
    /// Clone entity with all components
    func cloneDeep() -> Entity {
        return self.clone(recursive: true)
    }
}

// MARK: - ModelComponent Helpers

extension ModelComponent {
    
    /// Create simple box model
    @MainActor
    static func box(size: SIMD3<Float>, color: UIColor = .white) -> ModelComponent {
        let mesh = MeshResource.generateBox(size: size)
        let material = SimpleMaterial.create(color: color)
        return ModelComponent(
            mesh: mesh,
            materials: [material]
        )
    }
    
    /// Create simple sphere model
    @MainActor
    static func sphere(radius: Float, color: UIColor = .white) -> ModelComponent {
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = SimpleMaterial.create(color: color)
        return ModelComponent(
            mesh: mesh,
            materials: [material]
        )
    }
    
    /// Create simple cylinder model (using box as approximation)
    @MainActor
    static func cylinder(height: Float, radius: Float, color: UIColor = .white) -> ModelComponent {
        // Note: RealityKit only has generateBox, generateSphere, and generatePlane
        // Using a tall box as cylinder approximation
        let size = SIMD3<Float>(radius * 2, height, radius * 2)
        let mesh = MeshResource.generateBox(size: size)
        let material = SimpleMaterial.create(color: color)
        return ModelComponent(
            mesh: mesh,
            materials: [material]
        )
    }
    
    /// Create simple plane model
    @MainActor
    static func plane(width: Float, height: Float, color: UIColor = .white) -> ModelComponent {
        let mesh = MeshResource.generatePlane(
            width: width,
            height: height
        )
        let material = SimpleMaterial.create(color: color)
        return ModelComponent(
            mesh: mesh,
            materials: [material]
        )
    }
    
    /// Create model from mesh and single color
    @MainActor
    static func create(mesh: MeshResource, color: UIColor) -> ModelComponent {
        let material = SimpleMaterial.create(color: color)
        return ModelComponent(
            mesh: mesh,
            materials: [material]
        )
    }
    
    /// Create model from mesh and materials
    static func create(mesh: MeshResource, materials: [Material]) -> ModelComponent {
        return ModelComponent(
            mesh: mesh,
            materials: materials
        )
    }
}

// MARK: - Physics Helpers

extension PhysicsBodyComponent {
    
    /// Create dynamic physics body
    @MainActor
    static func dynamic(mass: Float = 1.0, shape: ShapeResource) -> PhysicsBodyComponent {
        return PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: mass),
            material: PhysicsMaterialResource.default,
            mode: .dynamic
        )
    }
    
    /// Create kinematic physics body
    @MainActor
    static func kinematic(mass: Float = 1.0, shape: ShapeResource) -> PhysicsBodyComponent {
        return PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: mass),
            material: PhysicsMaterialResource.default,
            mode: .kinematic
        )
    }
    
    /// Create static physics body
    @MainActor
    static func staticBody(shape: ShapeResource) -> PhysicsBodyComponent {
        return PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: 0.0),
            material: PhysicsMaterialResource.default,
            mode: .static
        )
    }
}

// MARK: - Collision Helpers

extension CollisionComponent {
    
    /// Create box collision
    @MainActor
    static func box(size: SIMD3<Float>) -> CollisionComponent {
        let shape = ShapeResource.generateBox(size: size)
        return CollisionComponent(shapes: [shape])
    }
    
    /// Create sphere collision
    @MainActor
    static func sphere(radius: Float) -> CollisionComponent {
        let shape = ShapeResource.generateSphere(radius: radius)
        return CollisionComponent(shapes: [shape])
    }
    
    /// Create cylinder collision (using box as approximation)
    @MainActor
    static func cylinder(height: Float, radius: Float) -> CollisionComponent {
        // Note: RealityKit ShapeResource only has generateBox and generateSphere
        // Using a box as cylinder approximation for collision
        let size = SIMD3<Float>(radius * 2, height, radius * 2)
        let shape = ShapeResource.generateBox(size: size)
        return CollisionComponent(shapes: [shape])
    }
    
    /// Create convex collision from mesh
    @MainActor
    static func convex(from mesh: MeshResource) -> CollisionComponent {
        let shape = ShapeResource.generateConvex(from: mesh)
        return CollisionComponent(shapes: [shape])
    }
}

// MARK: - Error Types

enum EntityError: Error {
    case missingFile(String)
    case conversionFailed(String)
    case invalidData
    
    var localizedDescription: String {
        switch self {
        case .missingFile(let filename):
            return "File not found: \(filename)"
        case .conversionFailed(let reason):
            return "Conversion failed: \(reason)"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}

import RealityKit
import UIKit

// MARK: - RealityKit Entity Extension

extension Entity {
    
    func removeAll() {
        isEnabled = false
        stopAllAnimations()
        removeFromParent()
    }
    
    func centerAlign() {
        // RealityKit equivalent of SCNNode centerAlign
        if let modelComponent = self.components[ModelComponent.self] {
            let bounds = modelComponent.mesh.bounds
            let extents = bounds.extents
            let offset = SIMD3<Float>(extents.x / 2, extents.y / 2, extents.z / 2) + bounds.min
            // Adjust the entity's transform to center align
            self.transform.translation = self.transform.translation - offset
        }
    }
    
    func move(toParent parent: Entity) {
        let currentTransform = self.transform
        removeFromParent()
        self.transform = currentTransform
        parent.addChild(self)
    }
    
    static func distanceBetween(_ entityA: Entity, _ entityB: Entity) -> Float {
        let posA = entityA.transform.translation
        let posB = entityB.transform.translation
        return distance(posA, posB)
    }
    
    func getRootEntity() -> Entity {
        var currentEntity = self
        while let parent = currentEntity.parent {
            currentEntity = parent
        }
        return currentEntity
    }
    
    func getTargetVector(target: Entity) -> (SIMD3<Float>, SIMD3<Float>) {
        let mat = target.transform.matrix
        let dir = SIMD3<Float>(
            -mat.columns.2.x,
             -mat.columns.2.y,
             -mat.columns.2.z
        )
        let pos = target.transform.translation
        return (dir, pos)
    }
    
    static func addFlash(contactPoint: SIMD3<Float>) -> Entity {
        let flashEntity = Entity()
        flashEntity.transform.translation = contactPoint
        // Create a bright light component
        let light = DirectionalLightComponent(
            color: .white,
            intensity: 4000,
            isRealWorldProxy: false
        )
        flashEntity.components.set(light)
        
        return flashEntity
    }
    
    static func runAndFadeExplosion(flashEntity: Entity) {
        // Simple fade using delayed removal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            flashEntity.removeFromParent()
        }
    }
    
    func generateMovementData(isAlive: Bool) -> MovementData? {
        return MovementData(entity: self, alive: isAlive)
    }
    
    func apply(movementData nodeData: MovementData, isHalfway: Bool) {
        guard nodeData.isAlive else { return }
        if isHalfway {
            // Smooth interpolation for halfway positioning
            let currentPos = self.transform.translation
            let currentRot = self.transform.rotation.eulerAngles
            self.transform.translation = (nodeData.position + currentPos) * 0.5
            // Convert euler angles to quaternion for RealityKit
            let newEuler = (nodeData.eulerAngles + currentRot) * 0.5
            self.transform.rotation = simd_quatf(angle: newEuler.y, axis: SIMD3(0, 1, 0)) *
            simd_quatf(
                angle: newEuler.x,
                axis: SIMD3(1, 0, 0)
            ) *
            simd_quatf(
                angle: newEuler.z,
                axis: SIMD3(0, 0, 1)
            )
        } else {
            // Direct positioning using SIMD types
            self.transform.translation = nodeData.position
            // Convert euler angles to quaternion for RealityKit
            self.transform.rotation = simd_quatf(
                angle: nodeData.eulerAngles.y,
                axis: SIMD3(0, 1, 0)
            ) *
            simd_quatf(
                angle: nodeData.eulerAngles.x,
                axis: SIMD3(1, 0, 0)
            ) *
            simd_quatf(
                angle: nodeData.eulerAngles.z,
                axis: SIMD3(0, 0, 1)
            )
        }
    }
}

extension Entity {
    func findFirstModelEntity() -> ModelEntity? {
        if let model = self as? ModelEntity {
            return model
        }
        for child in children {
            if let found = child.findFirstModelEntity() {
                return found
            }
        }
        return nil
    }
}
