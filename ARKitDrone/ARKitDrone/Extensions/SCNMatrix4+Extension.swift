//
//  SCNMatrix4+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNMatrix4 {
    
    public func toSimd() -> float4x4 {
        return float4x4(self)
    }
    
}
