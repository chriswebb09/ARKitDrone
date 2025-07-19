//
//  SCNMatrix4+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 9/3/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNMatrix4 {
    
    public func toSimd() -> float4x4 {
        return float4x4(self)
    }
    
    public func toSimdQuatf() -> simd_quatf {
            let rotationMatrix = float3x3(columns: (SIMD3<Float>(self.m11, self.m12, self.m13),
                                                    SIMD3<Float>(self.m21, self.m22, self.m23),
                                                    SIMD3<Float>(self.m31, self.m32, self.m33)))
            
            return simd_quatf(rotationMatrix)
        }
}


// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [
                translation.x,
                translation.y,
                translation.z
            ]
        }
        set(newValue) {
            columns.3 = [
                newValue.x,
                newValue.y,
                newValue.z,
                columns.3.w
            ]
        }
    }
    
    /**
     Factors out the orientation component of the transform.
     */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}
