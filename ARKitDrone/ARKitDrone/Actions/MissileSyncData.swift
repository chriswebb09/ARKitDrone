//
//  MissileSyncData.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/24/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//
import Foundation
import simd

/// Data structure for missile position updates
struct MissileSyncData: BitStreamCodable {
    let missileId: String
    let position: SIMD3<Float>
    let rotation: simd_quatf
    let timestamp: TimeInterval
    
    init(missileId: String, position: SIMD3<Float>, rotation: simd_quatf, timestamp: TimeInterval) {
          self.missileId = missileId
          self.position = position
          self.rotation = rotation
          self.timestamp = timestamp
      }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try missileId.encode(to: &bitStream)
        position.encode(to: &bitStream)
        try rotation.encode(to: &bitStream)
        bitStream.appendFloat64(timestamp)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        missileId = try String(from: &bitStream)
        position = try SIMD3<Float>(from: &bitStream)
        rotation = try simd_quatf(from: &bitStream)
        timestamp = try bitStream.readFloat64()
    }
}
