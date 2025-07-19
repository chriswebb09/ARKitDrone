//
//  ShapeResource+Conversion.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import SceneKit

extension ShapeResource {
    
    /// Create ShapeResource from SCNPhysicsShape
    static func from(_ scnPhysicsShape: SCNPhysicsShape) throws -> ShapeResource {
        // SceneKit physics shapes don't directly expose their underlying geometry,
        // so we need to work with the original geometry if available
        throw ConversionError.unsupportedConversion
    }
    
    /// Create ShapeResource from SCNGeometry for physics
    @MainActor
    static func from(_ scnGeometry: SCNGeometry) throws -> ShapeResource {
        // Try to determine the geometry type and create appropriate shape
        
        // Check for primitive geometries
        if let box = scnGeometry as? SCNBox {
            let size = SIMD3<Float>(Float(box.width), Float(box.height), Float(box.length))
            return .generateBox(size: size)
        }
        
        if let sphere = scnGeometry as? SCNSphere {
            return .generateSphere(radius: Float(sphere.radius))
        }
        
        if let cylinder = scnGeometry as? SCNCylinder {
            // RealityKit doesn't have generateCylinder, use a box approximation
            let size = SIMD3<Float>(Float(cylinder.radius * 2), Float(cylinder.height), Float(cylinder.radius * 2))
            return .generateBox(size: size)
        }
        
        if let capsule = scnGeometry as? SCNCapsule {
            // RealityKit doesn't have generateCapsule, use a box approximation
            let size = SIMD3<Float>(Float(capsule.capRadius * 2), Float(capsule.height), Float(capsule.capRadius * 2))
            return .generateBox(size: size)
        }
        
        if let plane = scnGeometry as? SCNPlane {
            let size = SIMD3<Float>(Float(plane.width), 0.01, Float(plane.height)) // Thin box for plane
            return .generateBox(size: size)
        }
        
        // For complex geometries, create convex hull from mesh
        return try .generateConvex(from: MeshResource.from(scnGeometry))
    }
    
    /// Create ShapeResource based on SCNPhysicsBody type and geometry
    @MainActor
    static func from(physicsBody: SCNPhysicsBody) throws -> ShapeResource {
        // SCNPhysicsShape doesn't expose its geometry, so we need to create a default shape
        // This is a limitation when converting from SceneKit to RealityKit
        
        // Create a default sphere shape - in practice, you'd want to pass the original geometry
        return .generateSphere(radius: 0.1)
    }
    
    /// Create primitive shapes for common physics bodies
    @MainActor
    static func box(size: SIMD3<Float>) -> ShapeResource {
        return .generateBox(size: size)
    }
    
    @MainActor
    static func sphere(radius: Float) -> ShapeResource {
        return .generateSphere(radius: radius)
    }
    
    @MainActor
    static func cylinder(height: Float, radius: Float) -> ShapeResource {
        // RealityKit doesn't have generateCylinder, use box approximation
        let size = SIMD3<Float>(radius * 2, height, radius * 2)
        return .generateBox(size: size)
    }
    
    @MainActor
    static func capsule(height: Float, radius: Float) -> ShapeResource {
        // RealityKit doesn't have generateCapsule, use box approximation  
        let size = SIMD3<Float>(radius * 2, height, radius * 2)
        return .generateBox(size: size)
    }
    
    @MainActor
    static func plane(size: SIMD2<Float>) -> ShapeResource {
        let boxSize = SIMD3<Float>(size.x, 0.01, size.y) // Thin box
        return .generateBox(size: boxSize)
    }
    
    /// Create convex hull from vertices
    @MainActor
    static func convexHull(from vertices: [SIMD3<Float>]) throws -> ShapeResource {
        var meshDescriptor = MeshDescriptor(name: "ConvexHull")
        meshDescriptor.positions = MeshBuffers.Positions(vertices)
        
        let meshResource = try MeshResource.generate(from: [meshDescriptor])
        return .generateConvex(from: meshResource)
    }
    
    /// Create shape from SCNNode's geometry
    @MainActor
    static func from(node: SCNNode) throws -> ShapeResource {
        guard let geometry = node.geometry else {
            throw ConversionError.missingGeometry
        }
        
        return try from(geometry)
    }
}

// MARK: - PhysicsBodyComponent Conversion

extension PhysicsBodyComponent {
    
    /// Create PhysicsBodyComponent from SCNPhysicsBody
    @MainActor
    static func from(_ scnPhysicsBody: SCNPhysicsBody) throws -> PhysicsBodyComponent {
        // Convert physics body type
        let mode: PhysicsBodyMode
        switch scnPhysicsBody.type {
        case .static:
            mode = .static
        case .dynamic:
            mode = .dynamic
        case .kinematic:
            mode = .kinematic
        @unknown default:
            mode = .static
        }
        
        // Create shape - SCNPhysicsShape doesn't expose geometry, so use default
        let shape = ShapeResource.generateSphere(radius: 0.01)
        let component = PhysicsBodyComponent(shapes: [shape], density: 1.0, mode: mode)
        
        // Note: RealityKit PhysicsBodyComponent doesn't have direct mass or gravity properties
        // Mass is calculated from density and volume automatically
        // Gravity is handled at the physics simulation level
        
        // Note: SCNPhysicsBody material properties are not directly accessible
        // Material properties would need to be set when creating the RealityKit component
        
        return component
    }
    
    /// Create simple physics body components
    @MainActor
    static func staticBox(size: SIMD3<Float>) -> PhysicsBodyComponent {
        let shape = ShapeResource.generateBox(size: size)
        return PhysicsBodyComponent(shapes: [shape], density: 1.0, mode: .static)
    }
    
    @MainActor
    static func dynamicSphere(radius: Float, density: Float = 1.0) -> PhysicsBodyComponent {
        let shape = ShapeResource.generateSphere(radius: radius)
        let component = PhysicsBodyComponent(shapes: [shape], density: density, mode: .dynamic)
        return component
    }
    
    @MainActor
    static func kinematicCylinder(height: Float, radius: Float) -> PhysicsBodyComponent {
        let shape = ShapeResource.cylinder(height: height, radius: radius)
        return PhysicsBodyComponent(shapes: [shape], density: 1.0, mode: .kinematic)
    }
}

// MARK: - Collision Detection Conversion

extension CollisionComponent {
    
    /// Create CollisionComponent from SCNPhysicsBody collision settings
    @MainActor
    static func from(_ scnPhysicsBody: SCNPhysicsBody) throws -> CollisionComponent {
        // SCNPhysicsShape doesn't expose geometry, so use default collision shape
        let shape = ShapeResource.generateSphere(radius: 0.01)
        let component = CollisionComponent(shapes: [shape])
        
        // Note: RealityKit uses a different collision system than SceneKit
        // Category and contact test bit masks need to be handled differently
        // This would require a separate collision group management system
        
        return component
    }
    
//    /// Create simple collision components
//    static func box(size: SIMD3<Float>) -> CollisionComponent {
//        let shape = ShapeResource.generateBox(size: size)
//        return CollisionComponent(shapes: [shape])
//    }
    
//    static func sphere(radius: Float) -> CollisionComponent {
//        let shape = ShapeResource.generateSphere(radius: radius)
//        return CollisionComponent(shapes: [shape])
//    }
}

// MARK: - Conversion Errors

extension ConversionError {
    static let unsupportedConversion = ConversionError.unsupportedFormat
    static let missingGeometry = ConversionError.missingData
}
