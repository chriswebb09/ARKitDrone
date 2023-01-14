//
//  SCNVector4+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNVector4 {
    
    init(_ vector: SIMD4<Float>) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
    }
}

