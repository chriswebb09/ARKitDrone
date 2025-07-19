//
//  simd_quatf+Extension.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import simd
import RealityKit

extension simd_quatf {
    
    /// RealityKit uses simd_quatf natively, so no conversion needed
    
    /// Create quaternion from Euler angles (in radians)
    static func angleConversion(x: Float, y: Float, z: Float) -> simd_quatf {
        let c1 = cos(x / 2)
        let c2 = cos(y / 2)
        let c3 = cos(z / 2)
        let s1 = sin(x / 2)
        let s2 = sin(y / 2)
        let s3 = sin(z / 2)
        let xF = s1 * c2 * c3 + c1 * s2 * s3
        let yF = c1 * s2 * c3 - s1 * c2 * s3
        let zF = c1 * c2 * s3 + s1 * s2 * c3
        let wF = c1 * c2 * c3 - s1 * s2 * s3
        return simd_quatf(
            ix: xF,
            iy: yF,
            iz: zF,
            r: wF
        )
    }
    
    /// Create quaternion from tuple (for compatibility)
    static func getQuaternion(from angleConversion: (Float, Float, Float, Float)) -> simd_quatf {
        return simd_quatf(
            ix: angleConversion.0,
            iy: angleConversion.1,
            iz: angleConversion.2,
            r: angleConversion.3
        )
    }
    
    /// Create quaternion from axis and angle
    init(axis: SIMD3<Float>, angle: Float) {
        let halfAngle = angle * 0.5
        let s = sin(halfAngle)
        let normalizedAxis = normalize(axis)
        self.init(
            ix: normalizedAxis.x * s,
            iy: normalizedAxis.y * s,
            iz: normalizedAxis.z * s,
            r: cos(halfAngle)
        )
    }
    
    /// Get axis and angle from quaternion
    var axisAngle: (axis: SIMD3<Float>, angle: Float) {
        let w = max(-1.0, min(1.0, self.real))
        let angle = 2.0 * acos(w)
        let s = sqrt(1.0 - w * w)
        if s < 0.001 {
            // If s is close to zero, direction of axis doesn't matter
            return (SIMD3<Float>(1, 0, 0), angle)
        } else {
            let axis = SIMD3<Float>(self.imag.x / s, self.imag.y / s, self.imag.z / s)
            return (axis, angle)
        }
    }
    
    /// Convert to Euler angles (in radians)
    var eulerAngles: SIMD3<Float> {
        let test = self.imag.x * self.imag.y + self.imag.z * self.real
        if test > 0.499 { // singularity at north pole
            let yaw = 2 * atan2(self.imag.x, self.real)
            let pitch = Float.pi / 2
            let roll: Float = 0
            return SIMD3<Float>(
                roll,
                pitch,
                yaw
            )
        }
        if test < -0.499 { // singularity at south pole
            let yaw = -2 * atan2(self.imag.x, self.real)
            let pitch = -Float.pi / 2
            let roll: Float = 0
            return SIMD3<Float>(
                roll,
                pitch,
                yaw
            )
        }
        let sqx = self.imag.x * self.imag.x
        let sqy = self.imag.y * self.imag.y
        let sqz = self.imag.z * self.imag.z
        let yaw = atan2(2 * self.imag.y * self.real - 2 * self.imag.x * self.imag.z, 1 - 2 * sqy - 2 * sqz)
        let pitch = asin(2 * test)
        let roll = atan2(2 * self.imag.x * self.real - 2 * self.imag.y * self.imag.z, 1 - 2 * sqx - 2 * sqz)
    
        return SIMD3<Float>(
            roll,
            pitch,
            yaw
        )
    }
    
    /// Spherical linear interpolation
    func slerp(to: simd_quatf, t: Float) -> simd_quatf {
        return simd_slerp(self, to, t)
    }
    
    /// Get the conjugate (inverse rotation)
    var conjugate: simd_quatf {
        return simd_quatf(
            ix: -self.imag.x,
            iy: -self.imag.y,
            iz: -self.imag.z,
            r: self.real
        )
    }
}
