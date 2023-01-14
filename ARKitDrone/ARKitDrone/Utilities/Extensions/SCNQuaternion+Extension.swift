//
//  SCNQuaternion+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNQuaternion {
    // https://developer.apple.com/forums/thread/651614?answerId=616792022#616792022
    
    static func angleConversion(x: Float, y: Float, z: Float, w: Float) -> (Float, Float, Float, Float) {
        let c1 = cos( x / 2 )
        let c2 = cos( y / 2 )
        let c3 = cos( z / 2 )
        let s1 = sin( x / 2 )
        let s2 = sin( y / 2 )
        let s3 = sin( z / 2 )
        let xF = s1 * c2 * c3 + c1 * s2 * s3
        let yF = c1 * s2 * c3 - s1 * c2 * s3
        let zF = c1 * c2 * s3 + s1 * s2 * c3
        let wF = c1 * c2 * c3 - s1 * s2 * s3
        return (xF, yF, zF, wF)
    }
}
