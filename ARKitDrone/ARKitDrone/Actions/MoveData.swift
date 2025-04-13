//
//  MoveData.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

struct MoveData {
    var velocity: GameVelocity
    var angular: Float
    var direction: Direction?
}

extension MoveData: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        velocity = try GameVelocity(from: &bitStream)
        direction = try Direction(from: &bitStream)
        angular = try bitStream.readFloat()
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        velocity.encode(to: &bitStream)
        direction?.encode(to: &bitStream)
        bitStream.appendFloat(angular)
    }
}
