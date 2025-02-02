//
//  SCNVector3+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 9/3/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

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


func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

func +=( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}
