//
//  SCNVector3+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 9/3/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func +=( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

extension SCNVector3 {
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
}

// from Apples demo APP

extension SCNVector3 {
    
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
}
