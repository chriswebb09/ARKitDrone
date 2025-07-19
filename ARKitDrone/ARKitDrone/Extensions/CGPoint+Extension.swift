//
//  CGPoint+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import RealityKit
import simd

// MARK: - CGPoint extensions

extension CGPoint {
    /// Create CGPoint from SIMD3<Float> (RealityKit equivalent)
    init(_ vector: SIMD3<Float>) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    /// Create CGPoint from SIMD2<Float>
    init(_ vector: SIMD2<Float>) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    /// Create CGPoint from screen projection of 3D point
    /// Manual projection implementation
    @MainActor
    init(projectedFrom worldPosition: SIMD3<Float>, in arView: ARView) {
        // Simple implementation without custom ARView extension dependency
        guard let frame = arView.session.currentFrame else {
            self.init(x: 0, y: 0)
            return
        }
        
        let viewMatrix = frame.camera.viewMatrix(for: .portrait)
        let projectionMatrix = frame.camera.projectionMatrix(for: .portrait, viewportSize: frame.camera.imageResolution, zNear: 0.01, zFar: 1000)
        
        // Transform world position to screen coordinates
        let worldPos4 = SIMD4<Float>(worldPosition.x, worldPosition.y, worldPosition.z, 1.0)
        let cameraPos = viewMatrix * worldPos4
        let clipPos = projectionMatrix * cameraPos
        
        guard clipPos.w != 0 else {
            self.init(x: 0, y: 0)
            return
        }
        
        let ndc = SIMD2<Float>(clipPos.x / clipPos.w, clipPos.y / clipPos.w)
        let screenSize = arView.bounds.size
        let screenX = (ndc.x + 1.0) * 0.5 * Float(screenSize.width)
        let screenY = (1.0 - ndc.y) * 0.5 * Float(screenSize.height)
        
        self.init(x: CGFloat(screenX), y: CGFloat(screenY))
    }
    
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
    
    /// Convert CGPoint to SIMD2<Float> for RealityKit calculations
    var simd2: SIMD2<Float> {
        return SIMD2<Float>(Float(x), Float(y))
    }
    
    /// Calculate distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Normalize the point as a vector
    var normalized: CGPoint {
        let len = length
        guard len > 0 else { return CGPoint.zero }
        return CGPoint(x: x / len, y: y / len)
    }
    
    /// Create a point by interpolating between two points
    static func lerp(from start: CGPoint, to end: CGPoint, t: CGFloat) -> CGPoint {
        let clampedT = max(0, min(1, t))
        return CGPoint(
            x: start.x + (end.x - start.x) * clampedT,
            y: start.y + (end.y - start.y) * clampedT
        )
    }
}

// MARK: - ARView Screen-World Conversion Helpers

extension ARView {
    
    /// Project a 3D world position to 2D screen coordinates
    func projectWorldToScreen(_ worldPosition: SIMD3<Float>) -> SIMD2<Float> {
        // Get the camera's view and projection matrices
        guard let frame = session.currentFrame else {
            return SIMD2<Float>(0, 0)
        }
        
        let viewMatrix = frame.camera.viewMatrix(for: .portrait)
        let projectionMatrix = frame.camera.projectionMatrix(for: .portrait, viewportSize: frame.camera.imageResolution, zNear: 0.01, zFar: 1000)
        
        // Transform world position to camera space
        let worldPos4 = SIMD4<Float>(worldPosition.x, worldPosition.y, worldPosition.z, 1.0)
        let cameraPos = viewMatrix * worldPos4
        
        // Project to screen space
        let clipPos = projectionMatrix * cameraPos
        
        // Perspective divide
        guard clipPos.w != 0 else {
            return SIMD2<Float>(0, 0)
        }
        
        let ndc = SIMD2<Float>(clipPos.x / clipPos.w, clipPos.y / clipPos.w)
        
        // Convert from NDC (-1 to 1) to screen coordinates
        let screenSize = bounds.size
        let screenX = (ndc.x + 1.0) * 0.5 * Float(screenSize.width)
        let screenY = (1.0 - ndc.y) * 0.5 * Float(screenSize.height) // Flip Y axis
        
        return SIMD2<Float>(screenX, screenY)
    }
    
//    /// Convert screen point to world ray for raycasting
//    func ray(from screenPoint: CGPoint) -> (origin: SIMD3<Float>, direction: SIMD3<Float>) {
//        guard let frame = session.currentFrame else {
//            return (SIMD3<Float>(0, 0, 0), SIMD3<Float>(0, 0, -1))
//        }
//        
//        let camera = frame.camera
//        let viewSize = bounds.size
//        
//        // Convert screen coordinates to normalized device coordinates
//        let x = (2.0 * Float(screenPoint.x) / Float(viewSize.width)) - 1.0
//        let y = 1.0 - (2.0 * Float(screenPoint.y) / Float(viewSize.height))
//        
//        // Get camera matrices
//        let viewMatrix = camera.viewMatrix(for: .portrait)
//        let projectionMatrix = camera.projectionMatrix(for: .portrait, viewportSize: camera.imageResolution, zNear: 0.01, zFar: 1000)
//        
//        // Create ray in NDC space
//        let nearPoint = SIMD4<Float>(x, y, -1.0, 1.0)
//        let farPoint = SIMD4<Float>(x, y, 1.0, 1.0)
//        
//        // Transform to world space
//        let invViewProj = (projectionMatrix * viewMatrix).inverse
//        
//        let worldNear = invViewProj * nearPoint
//        let worldFar = invViewProj * farPoint
//        
//        // Perspective divide
//        let rayOrigin = SIMD3<Float>(worldNear.x / worldNear.w, worldNear.y / worldNear.w, worldNear.z / worldNear.w)
//        let rayEnd = SIMD3<Float>(worldFar.x / worldFar.w, worldFar.y / worldFar.w, worldFar.z / worldFar.w)
//        
//        let rayDirection = normalize(rayEnd - rayOrigin)
//        
//        return (rayOrigin, rayDirection)
//    }
}
