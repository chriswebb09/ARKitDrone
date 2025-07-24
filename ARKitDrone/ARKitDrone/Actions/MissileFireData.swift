//
//  MissileFireData.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/24/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

// MARK: - Missile Synchronization Data

/// Data structure for missile firing events
struct MissileFireData: BitStreamCodable {
    let missileId: String
    let playerId: String
    let startPosition: SIMD3<Float>
    let startRotation: simd_quatf
    let targetShipId: String
    let fireTime: TimeInterval
    
    init(missileId: String, playerId: String, startPosition: SIMD3<Float>, startRotation: simd_quatf, targetShipId: String, fireTime: TimeInterval) {
        self.missileId = missileId
        self.playerId = playerId
        self.startPosition = startPosition
        self.startRotation = startRotation
        self.targetShipId = targetShipId
        self.fireTime = fireTime
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try missileId.encode(to: &bitStream)
        try playerId.encode(to: &bitStream)
        startPosition.encode(to: &bitStream)
        try startRotation.encode(to: &bitStream)
        try targetShipId.encode(to: &bitStream)
        bitStream.appendFloat64(fireTime)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        missileId = try String(from: &bitStream)
        playerId = try String(from: &bitStream)
        startPosition = try SIMD3<Float>(from: &bitStream)
        startRotation = try simd_quatf(from: &bitStream)
        targetShipId = try String(from: &bitStream)
        fireTime = try bitStream.readFloat64()
    }
}
