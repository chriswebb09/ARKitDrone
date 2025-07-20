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
        let size = SIMD3<Float>(
            radius * 2,
            height,
            radius * 2
        )
        return .generateBox(size: size)
    }
    
    @MainActor
    static func capsule(height: Float, radius: Float) -> ShapeResource {
        // RealityKit doesn't have generateCapsule, use box approximation  
        let size = SIMD3<Float>(
            radius * 2,
            height,
            radius * 2
        )
        return .generateBox(size: size)
    }
    
    @MainActor
    static func plane(size: SIMD2<Float>) -> ShapeResource {
        let boxSize = SIMD3<Float>(
            size.x,
            0.01,
            size.y
        ) // Thin box
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
}

// MARK: - PhysicsBodyComponent Conversion

extension PhysicsBodyComponent {
    
    /// Create simple physics body components
    @MainActor
    static func staticBox(size: SIMD3<Float>) -> PhysicsBodyComponent {
        let shape = ShapeResource.generateBox(size: size)
        return PhysicsBodyComponent(
            shapes: [shape],
            density: 1.0,
            mode: .static
        )
    }
    
    @MainActor
    static func dynamicSphere(radius: Float, density: Float = 1.0) -> PhysicsBodyComponent {
        let shape = ShapeResource.generateSphere(radius: radius)
        let component = PhysicsBodyComponent(
            shapes: [shape],
            density: density,
            mode: .dynamic
        )
        return component
    }
    
    @MainActor
    static func kinematicCylinder(height: Float, radius: Float) -> PhysicsBodyComponent {
        let shape = ShapeResource.cylinder(
            height: height,
            radius: radius
        )
        return PhysicsBodyComponent(
            shapes: [shape],
            density: 1.0,
            mode: .kinematic
        )
    }
}

// MARK: - Conversion Errors

extension ConversionError {
    static let unsupportedConversion = ConversionError.unsupportedFormat
    static let missingGeometry = ConversionError.missingData
}
