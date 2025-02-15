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
    
}

extension SCNVector3 {
    
    public func toSimd() -> SIMD3<Float> {
        return SIMD3<Float>(self)
    }
}
