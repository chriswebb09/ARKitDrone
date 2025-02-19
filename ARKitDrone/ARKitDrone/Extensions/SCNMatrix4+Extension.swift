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

//extension float4x4 {
//    /**
//     Treats matrix as a (right-hand column-major convention) transform matrix
//     and factors out the translation component of the transform.
//     */
//    var translation: SIMD3<Float> {
//        get {
//            let translation = columns.3
//            return [translation.x, translation.y, translation.z]
//        }
//        set(newValue) {
//            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
//        }
//    }
//    
//}

