//
//  SIMD3+Extension.swift
//  ARKitDrone
//
//  Created on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import simd

extension SIMD3<Float> {
    
    /// Rotate vector by quaternion
    func rotate(by quaternion: simd_quatf) -> SIMD3<Float> {
        return quaternion.act(self)
    }
    
    /// Rescale vector to desired length
    func rescaled(to desiredLength: Float) -> SIMD3<Float> {
        let currentLength = length(self)
        guard currentLength > 0 else { return self }
        let coef = desiredLength / currentLength
        return self * coef
    }
    
    /// Normalize vector to unit length
    var normalized: SIMD3<Float> {
        return simd.normalize(self)
    }
    
    /// Get vector length/magnitude
    var magnitude: Float {
        return length(self)
    }
    
    /// Create position from transform matrix
    static func positionFromTransform(_ transform: simd_float4x4) -> SIMD3<Float> {
        return SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
    }
    
    /// Negate vector
    func negated() -> SIMD3<Float> {
        return -self
    }
    
    /// Calculate distance to another vector
    func distance(to vector: SIMD3<Float>) -> Float {
        return length(self - vector)
    }
    
    /// Calculate cross product
    func cross(_ vector: SIMD3<Float>) -> SIMD3<Float> {
        return simd.cross(self, vector)
    }
}

// MARK: - Global Functions for compatibility

/// Returns the length (magnitude) of the vector
func SIMD3Length(_ vector: SIMD3<Float>) -> Float {
    return length(vector)
}

/// Returns the distance between two SIMD3 vectors
func SIMD3Distance(_ vectorStart: SIMD3<Float>, vectorEnd: SIMD3<Float>) -> Float {
    return vectorStart.distance(to: vectorEnd)
}

/// Normalizes a SIMD3 vector
func SIMD3Normalize(_ vector: SIMD3<Float>) -> SIMD3<Float> {
    return normalize(vector)
}

/// Calculates the dot product between two SIMD3 vectors
func SIMD3DotProduct(_ left: SIMD3<Float>, right: SIMD3<Float>) -> Float {
    return dot(left, right)
}

/// Calculates the cross product between two SIMD3 vectors
func SIMD3CrossProduct(_ left: SIMD3<Float>, right: SIMD3<Float>) -> SIMD3<Float> {
    return cross(left, right)
}

/// Project one vector onto another
func SIMD3Project(_ vectorToProject: SIMD3<Float>, projectionVector: SIMD3<Float>) -> SIMD3<Float> {
    let scale = dot(projectionVector, vectorToProject) / dot(projectionVector, projectionVector)
    return projectionVector * scale
}

// MARK: - Division operators for Int compatibility

func / (left: SIMD3<Float>, right: Int) -> SIMD3<Float> {
    return left / Float(right)
}

func /= (left: inout SIMD3<Float>, right: Int) {
    left = left / Float(right)
}

// MARK: - SIMD4<Float> Extensions

extension SIMD4<Float> {
    /// Extract xyz components as SIMD3<Float>
    var xyz: SIMD3<Float> {
        get {
            return SIMD3<Float>(x, y, z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    
    /// Initialize from SIMD3 + w component
    init(_ xyz: SIMD3<Float>, _ w: Float) {
        self.init(xyz.x, xyz.y, xyz.z, w)
    }
    
    /// Check for NaN values
    var hasNaN: Bool {
        return x.isNaN || y.isNaN || z.isNaN || w.isNaN
    }
    
    /// Zero vector
    static let zero = SIMD4<Float>(repeating: 0.0)
}
