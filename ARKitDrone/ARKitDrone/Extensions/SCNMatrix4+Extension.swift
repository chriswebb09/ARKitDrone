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
