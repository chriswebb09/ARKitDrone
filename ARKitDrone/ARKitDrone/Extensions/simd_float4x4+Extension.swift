//
//  simd_float4x4+Extension.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import simd
import RealityKit

extension simd_float4x4 {
    /// Extract quaternion rotation from matrix
    public func toQuaternion() -> simd_quatf {
        let rotationMatrix = float3x3(columns: (
            SIMD3<Float>(self.columns.0.x, self.columns.0.y, self.columns.0.z),
            SIMD3<Float>(self.columns.1.x, self.columns.1.y, self.columns.1.z),
            SIMD3<Float>(self.columns.2.x, self.columns.2.y, self.columns.2.z)
        ))
        return simd_quatf(rotationMatrix)
    }
    
    /// Get scale factors from matrix
    var scale: SIMD3<Float> {
        let scaleX = length(
            SIMD3<Float>(columns.0.x, columns.0.y, columns.0.z)
        )
        let scaleY = length(
            SIMD3<Float>(columns.1.x, columns.1.y, columns.1.z)
        )
        let scaleZ = length(
            SIMD3<Float>(columns.2.x, columns.2.y, columns.2.z)
        )
        return SIMD3<Float>(scaleX, scaleY, scaleZ)
    }
    
    /// Create transform matrix from translation, rotation, and scale
    init(translation: SIMD3<Float>, rotation: simd_quatf, scale: SIMD3<Float>) {
        let rotationMatrix = float4x4(rotation)
        let scaleMatrix = float4x4(
            diagonal: SIMD4<Float>(scale.x, scale.y, scale.z, 1.0)
        )
        let translationMatrix = float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(translation.x, translation.y, translation.z, 1)
        )
        self = translationMatrix * rotationMatrix * scaleMatrix
    }
    
    /// Create transform matrix with uniform scale
    init(translation: SIMD3<Float>, rotation: simd_quatf, uniformScale: Float) {
        self.init(
            translation: translation,
            rotation: rotation,
            scale: SIMD3<Float>(uniformScale, uniformScale, uniformScale)
        )
    }
    
    /// Create look-at matrix
    static func lookAt(eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) -> simd_float4x4 {
        let forward = normalize(target - eye)
        let right = normalize(cross(forward, up))
        let newUp = cross(right, forward)
        return simd_float4x4(columns: (
            SIMD4<Float>(right.x, newUp.x, -forward.x, 0),
            SIMD4<Float>(right.y, newUp.y, -forward.y, 0),
            SIMD4<Float>(right.z, newUp.z, -forward.z, 0),
            SIMD4<Float>(-dot(right, eye), -dot(newUp, eye), dot(forward, eye), 1)
        ))
    }
    
    /// Create perspective projection matrix
    static func perspective(fovy: Float, aspect: Float, near: Float, far: Float) -> simd_float4x4 {
        let f = 1.0 / tan(fovy * 0.5)
        let rangeInv = 1.0 / (near - far)
        return simd_float4x4(columns: (
            SIMD4<Float>(f / aspect, 0, 0, 0),
            SIMD4<Float>(0, f, 0, 0),
            SIMD4<Float>(0, 0, (far + near) * rangeInv, -1),
            SIMD4<Float>(0, 0, 2 * far * near * rangeInv, 0)
        ))
    }
}
