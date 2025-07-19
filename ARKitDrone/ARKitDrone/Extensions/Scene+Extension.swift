//
//  RealityKit+Extensions.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import ARKit
import simd

// MARK: - RealityKit Entity Loading Extensions

extension Entity {
    
    /// Load entity from model file (RealityKit equivalent of SCNScene.nodeWithModelName)
    static func entityWithModelName(_ modelName: String, in bundle: Bundle = .main) async throws -> Entity {
        // Try common RealityKit file extensions
        let extensions = ["usdz", "reality", "rcproject"]
        for ext in extensions {
            if let url = bundle.url(
                forResource: modelName,
                withExtension: ext
            ) {
                return try await Entity(contentsOf: url)
            }
        }
        // If no file found with extensions, try without extension
        if let url = bundle.url(
            forResource: modelName,
            withExtension: nil
        ) {
            return try await Entity(contentsOf: url)
        }
        throw EntityLoadingError.fileNotFound(modelName)
    }
    
    /// Load entity synchronously (for compatibility with older patterns)
    static func entityWithModelNameSync(_ modelName: String, in bundle: Bundle = .main) -> Entity? {
        let extensions = ["usdz", "reality", "rcproject"]
        for ext in extensions {
            if let url = bundle.url(
                forResource: modelName,
                withExtension: ext
            ) {
                do {
                    return try Entity.load(contentsOf: url)
                } catch {
                    continue
                }
            }
        }
        return nil
    }
}

// MARK: - simd_float4x4 Extensions

extension simd_float4x4 {
    
    /// Create translation matrix
    init(translation vector: SIMD3<Float>) {
        self.init(
            SIMD4(1, 0, 0, 0),
            SIMD4(0, 1, 0, 0),
            SIMD4(0, 0, 1, 0),
            SIMD4(
                vector.x,
                vector.y,
                vector.z,
                1
            )
        )
    }
    
    
    /// Create rotation matrix from quaternion
    init(rotation quaternion: simd_quatf) {
        self = simd_float4x4(quaternion)
    }
    
    /// Create scale matrix
    init(scale vector: SIMD3<Float>) {
        self.init(SIMD4(vector.x, 0, 0, 0),
                  SIMD4(0, vector.y, 0, 0),
                  SIMD4(0, 0, vector.z, 0),
                  SIMD4(0, 0, 0, 1))
    }
}

// MARK: - ARView Extensions (RealityKit equivalent of ARSCNView)

extension ARView {
    
    /// Convert 3D world point to 2D screen point
    func projectPoint(_ point: SIMD3<Float>) -> SIMD2<Float> {
        guard let frame = session.currentFrame else {
            return SIMD2<Float>(0, 0)
        }
        let viewMatrix = frame.camera.viewMatrix(for: .portrait)
        let projectionMatrix = frame.camera.projectionMatrix(
            for: .portrait,
            viewportSize: frame.camera.imageResolution,
            zNear: 0.01,
            zFar: 1000
        )
        // Transform world position to screen coordinates
        let worldPos4 = SIMD4<Float>(
            point.x,
            point.y,
            point.z,
            1.0
        )
        let cameraPos = viewMatrix * worldPos4
        let clipPos = projectionMatrix * cameraPos
        guard clipPos.w != 0 else {
            return SIMD2<Float>(0, 0)
        }
        let ndc = SIMD2<Float>(clipPos.x / clipPos.w, clipPos.y / clipPos.w)
        let screenSize = bounds.size
        let screenX = (ndc.x + 1.0) * 0.5 * Float(screenSize.width)
        let screenY = (1.0 - ndc.y) * 0.5 * Float(screenSize.height)
        return SIMD2<Float>(screenX, screenY)
    }
    
    /// Convert 2D screen point to 3D world ray (inverse of projection)
    func unprojectPoint(_ screenPoint: SIMD2<Float>) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
        let cgPoint = CGPoint(
            x: CGFloat(screenPoint.x),
            y: CGFloat(screenPoint.y)
        )
        return ray(from: cgPoint)
    }
    
    /// Cast ray for ARRaycastQuery (already available in ARView)
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }
    
    /// Get raycast query for screen center or specific alignment
    ///
   func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        guard let frame = session.currentFrame else { return nil }
       return frame.raycastQuery(
        from: screenCenter,
        allowing: .estimatedPlane,
        alignment: alignment
       )
    }
    
    /// Get the center point of the screen
    var screenCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convert screen point to world ray
    func ray(from screenPoint: CGPoint) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
        guard let frame = session.currentFrame else {
            return (SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, -1))
        }
        let camera = frame.camera
        let viewSize = bounds.size
        // Convert screen coordinates to normalized device coordinates
        let x = (2.0 * Float(screenPoint.x) / Float(viewSize.width)) - 1.0
        let y = 1.0 - (2.0 * Float(screenPoint.y) / Float(viewSize.height))
        
        // Get camera matrices
        let viewMatrix = camera.viewMatrix(for: .portrait)
        let projectionMatrix = camera.projectionMatrix(
            for: .portrait,
            viewportSize: camera.imageResolution,
            zNear: 0.01,
            zFar: 1000
        )
        // Create ray in NDC space
        let nearPoint = SIMD4<Float>(x, y, -1.0, 1.0)
        let farPoint = SIMD4<Float>(x, y, 1.0, 1.0)
        // Transform to world space
        let invViewProj = (projectionMatrix * viewMatrix).inverse
        let worldNear = invViewProj * nearPoint
        let worldFar = invViewProj * farPoint
        // Perspective divide
        let rayOrigin = SIMD3<Float>(worldNear.x / worldNear.w, worldNear.y / worldNear.w, worldNear.z / worldNear.w)
        let rayEnd = SIMD3<Float>(worldFar.x / worldFar.w, worldFar.y / worldFar.w, worldFar.z / worldFar.w)
        let rayDirection = normalize(rayEnd - rayOrigin)
        return (rayOrigin, rayDirection)
    }
}

// MARK: - Error Types

enum EntityLoadingError: Error {
    case fileNotFound(String)
    case loadingFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .fileNotFound(let filename):
            return "Entity file not found: \(filename)"
        case .loadingFailed(let reason):
            return "Entity loading failed: \(reason)"
        }
    }
}
