//
//  MissileHitData.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/24/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

/// Data structure for missile hit events
struct MissileHitData: BitStreamCodable {
    let missileId: String
    let shipId: String
    let hitPosition: SIMD3<Float>
    let playerId: String
    let timestamp: TimeInterval
    
    init(missileId: String, shipId: String, hitPosition: SIMD3<Float>, playerId: String, timestamp: TimeInterval) {
        self.missileId = missileId
        self.shipId = shipId
        self.hitPosition = hitPosition
        self.playerId = playerId
        self.timestamp = timestamp
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try missileId.encode(to: &bitStream)
        try shipId.encode(to: &bitStream)
        hitPosition.encode(to: &bitStream)
        try playerId.encode(to: &bitStream)
        bitStream.appendFloat64(timestamp)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        missileId = try String(from: &bitStream)
        shipId = try String(from: &bitStream)
        hitPosition = try SIMD3<Float>(from: &bitStream)
        playerId = try String(from: &bitStream)
        timestamp = try bitStream.readFloat64()
    }
}
