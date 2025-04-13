//
//  GameVelocity.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

struct GameVelocity {
    var vector: SIMD3<Float>
    static var zero: GameVelocity { return GameVelocity(vector: SIMD3<Float>()) }
}

extension GameVelocity: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        vector = try SIMD3<Float>(from: &bitStream)
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        vector.encode(to: &bitStream)
    }
}
