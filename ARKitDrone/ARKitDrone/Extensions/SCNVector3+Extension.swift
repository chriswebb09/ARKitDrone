//
//  SCNVector3+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNVector3 {
    
    func distance(to destination: SCNVector3) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
    }
    
    func normalized() -> SCNVector3 {
        let magnitude = ((self.x * self.x) + (self.y * self.y) + (self.z * self.z)).squareRoot()
        return SCNVector3(self.x / magnitude, self.y / magnitude, self.z / magnitude)
    }
    
    enum Axis {
        case x, y, z
        
        func getAxisVector() -> simd_float3 {
            switch self {
            case .x:
                return simd_float3(1,0,0)
            case .y:
                return simd_float3(0,1,0)
            case .z:
                return simd_float3(0,0,1)
            }
        }
    }
    
    func rotatedVector(aroundAxis: Axis, angle: Float) -> SCNVector3 {
        let q = simd_quatf(angle: angle, axis: aroundAxis.getAxisVector())
        let simdVector = q.act(simd_float3(self))
        return SCNVector3(simdVector)
    }
}
