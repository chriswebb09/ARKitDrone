//
//  simd_quatf+AdditionalHelpers.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 9/3/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import simd
import RealityKit

// Additional quaternion helpers that complement the main simd_quatf extension
extension simd_quatf {
    
    /// Create identity quaternion
    static var identity: simd_quatf {
        return simd_quatf(
            ix: 0,
            iy: 0,
            iz: 0,
            r: 1
        )
    }
    
    /// Rotate around X axis
    static func rotationX(_ angle: Float) -> simd_quatf {
        return simd_quatf(
            angle: angle,
            axis: SIMD3<Float>(1, 0, 0)
        )
    }
    
    /// Rotate around Y axis
    static func rotationY(_ angle: Float) -> simd_quatf {
        return simd_quatf(
            angle: angle,
            axis: SIMD3<Float>(0, 1, 0)
        )
    }
    
    /// Rotate around Z axis
    static func rotationZ(_ angle: Float) -> simd_quatf {
        return simd_quatf(
            angle: angle,
            axis: SIMD3<Float>(0, 0, 1)
        )
    }
    
    /// Create quaternion from individual components (RealityKit uses ix, iy, iz, r)
    init(x: Float, y: Float, z: Float, w: Float) {
        self.init(
            ix: x,
            iy: y,
            iz: z,
            r: w
        )
    }
    
    /// Get individual components as tuple (x, y, z, w)
    var components: (x: Float, y: Float, z: Float, w: Float) {
        return (
            self.imag.x,
            self.imag.y,
            self.imag.z,
            self.real
        )
    }
    
    /// Multiply quaternions (combine rotations)
    static func * (lhs: simd_quatf, rhs: simd_quatf) -> simd_quatf {
        return simd_mul(lhs, rhs)
    }
}
