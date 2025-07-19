//
//  AddNodeAction.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

struct AddNodeAction {
    var simdWorldTransform: float4x4
    var eulerAngles: SIMD3<Float>
}

extension AddNodeAction: BitStreamCodable {
    
    init(from bitStream: inout ReadableBitStream) throws {
        simdWorldTransform = try float4x4(from: &bitStream)
        eulerAngles = try SIMD3<Float>(from: &bitStream)
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        simdWorldTransform.encode(to: &bitStream)
        eulerAngles.encode(to: &bitStream)
    }
}
