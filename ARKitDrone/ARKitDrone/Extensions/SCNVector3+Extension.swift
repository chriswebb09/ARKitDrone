//
//  SCNVector3+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 9/3/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNVector3 {
    
    public func toSimd() -> SIMD3<Float> {
        return SIMD3<Float>(self)
    }
    
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    func rotate(by quaternion: SCNQuaternion) -> SCNVector3 {
        // Convert the vector to a quaternion (w = 0)
        let vectorQuat = SCNQuaternion(self.x, self.y, self.z, 0)
        
        // Conjugate of the quaternion (invert its vector part)
        let conjugateQuat = SCNQuaternion(-quaternion.x, -quaternion.y, -quaternion.z, quaternion.w)
        
        // Apply the rotation: q * v * q^-1
        let resultQuat = quaternionMultiply(quaternionMultiply(quaternion, vectorQuat), conjugateQuat)
        
        // Return the rotated vector (x, y, z)
        return SCNVector3(resultQuat.x, resultQuat.y, resultQuat.z)
    }
    
    private func quaternionMultiply(_ q1: SCNQuaternion, _ q2: SCNQuaternion) -> SCNQuaternion {
        return SCNQuaternion(
            q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
            q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w,
            q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        )
    }
    
    // from Apples demo APP
    
    func rescaled(to desiredLength: Float) -> SCNVector3 {
        let length = sqrt(x * x + y * y + z * z)
        let coef = desiredLength / length
        return SCNVector3(
            x: x * coef,
            y: y * coef,
            z: z * coef
        )
    }
    
    func normalized() -> SCNVector3 {
        let magnitude = ((self.x * self.x) + (self.y * self.y) + (self.z * self.z)).squareRoot()
        return SCNVector3(self.x / magnitude, self.y / magnitude, self.z / magnitude)
    }
    
    /// Returns a position in SCNVector3
    /// from matrix_float4x4
    ///
    /// - Parameters:
    ///     - transform: The *transform* matrix from which the coordinate is derived.
    ///
    /// - Returns: the positon in SCNVector3 from `transform`.
    
    static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    /**
     * Negates the vector described by SCNVector3 and returns
     * the result as a new SCNVector3.
     */
    func negate() -> SCNVector3 {
        return self * -1
    }
    
    /**
     * Negates the vector described by SCNVector3
     */
    mutating func negated() -> SCNVector3 {
        self = negate()
        return self
    }
    
    
    /**
     * Returns the length (magnitude) of the vector described by the SCNVector3
     */
    func length() -> Float {
        return sqrtf(((Float(x) * Float(x)) + (Float(y) * Float(y))) + (Float(z) * Float(z)))
    }
    
    
    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0.
     */
    mutating func normalize() -> SCNVector3 {
        self = normalized()
        return self
    }
    
    /**
     * Calculates the distance between two SCNVector3. Pythagoras!
     */
    func distance(_ vector: SCNVector3) -> Float {
        return (self - vector).length()
    }
    
    /**
     * Calculates the dot product between two SCNVector3.
     */
    func dot(_ vector: SCNVector3) -> Float {
        return (((Float(x) * Float(vector.x)) + (Float(y) * Float(vector.y))) + (Float(z) * Float(vector.z)))
    }
    
    /**
     * Calculates the cross product between two SCNVector3.
     */
    func cross(_ vector: SCNVector3) -> SCNVector3 {
        return SCNVector3(x:((y * vector.z) - (z * vector.y)), y: ((z * vector.x) - (x * vector.z)), z: ((x * vector.y) - (y * vector.x)))
    }
}

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func +=( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

/**
 * Multiplies a SCNVector3 with another.
 */
func *= (left: inout SCNVector3, right: SCNVector3) {
    left = SCNVector3(left.x * right.x, left.y * right.y, left.z * right.z)
}

/**
 * Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
 * returns the result as a new SCNVector3.
 */

func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3(x: vector.x * scalar, y: vector.y * scalar, z: vector.z * scalar)
}

/**
 * Multiplies the x and y fields of a SCNVector3 with the same scalar value.
 */
func *= (vector: inout SCNVector3, scalar: Float) {
    vector = vector * scalar
}

/**
 * Divides two SCNVector3 vectors abd returns the result as a new SCNVector3
 */
infix operator /
func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: left.x / right.x, y: left.y / right.y, z: left.z / right.z)
}

/**
 * Divides a SCNVector3 by another.
 */
func /= (left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

/**
 * Divides the x, y and z fields of a SCNVector3 by the same scalar value and
 * returns the result as a new SCNVector3.
 */
func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3(x: vector.x / Float(scalar), y: vector.y / Float(scalar), z: vector.z / Float(scalar))
}

/**
 * Divides the x, y and z of a SCNVector3 by the same scalar value.
 */
func /= (vector: inout SCNVector3, scalar: Float) {
    vector = vector / scalar
}

/**
 * Negate a vector
 */
func SCNVector3Negate(_ vector: SCNVector3) -> SCNVector3 {
    return vector * -1
}

/**
 * Returns the length (magnitude) of the vector described by the SCNVector3
 */
func SCNVector3Length(_ vector: SCNVector3) -> Float {
    return sqrtf((Float(vector.x * vector.x) + Float(vector.y * vector.y)) + Float(vector.z * vector.z))
}

/**
 * Returns the distance between two SCNVector3 vectors
 */
func SCNVector3Distance(_ vectorStart: SCNVector3, vectorEnd: SCNVector3) -> Float {
    return (vectorEnd - vectorStart).length()
}

/**
 * Returns the distance between two SCNVector3 vectors
 */
func SCNVector3Normalize(_ vector: SCNVector3) -> SCNVector3 {
    return vector / SCNVector3Length(vector)
}

/**
 * Calculates the dot product between two SCNVector3 vectors
 */
func SCNVector3DotProduct(_ left: SCNVector3, right: SCNVector3) -> Float {
    return Float(((left.x * right.x) + (left.y * right.y)) + (left.z * right.z))
}

/**
 * Calculates the cross product between two SCNVector3 vectors
 */
func SCNVector3CrossProduct(_ left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: ((left.y * right.z) - (left.z * right.y)), y: ((left.z * right.x) - (left.x * right.z)), z: ((left.x * right.y) - (left.y * right.x)))
}


/**
 * Project the vector, vectorToProject, onto the vector, projectionVector.
 */
func SCNVector3Project(_ vectorToProject: SCNVector3, projectionVector: SCNVector3) -> SCNVector3 {
    let scale: Float = SCNVector3DotProduct(projectionVector, right: vectorToProject) / SCNVector3DotProduct(projectionVector, right: projectionVector)
    let v: SCNVector3 = projectionVector * scale
    return v
}


func / (left: SCNVector3, right: Int) -> SCNVector3 {
    return SCNVector3(x: left.x / Float(right), y: left.y / Float(right), z: left.z / Float(right))
}
