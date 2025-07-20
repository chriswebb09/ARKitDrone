//
//  SyncDataStructures.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

// MARK: - Ship Synchronization Data

/// Data structure for synchronizing ship state across clients
struct ShipSyncData: BitStreamCodable {
    let shipId: String
    let position: SIMD3<Float>
    let velocity: SIMD3<Float>
    let rotation: simd_quatf
    let isDestroyed: Bool
    let targeted: Bool
    
    init(
        shipId: String,
        position: SIMD3<Float>,
        velocity: SIMD3<Float>,
        rotation: simd_quatf,
        isDestroyed: Bool,
        targeted: Bool
    ) {
        self.shipId = shipId
        self.position = position
        self.velocity = velocity
        self.rotation = rotation
        self.isDestroyed = isDestroyed
        self.targeted = targeted
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try shipId.encode(to: &bitStream)
        try position.encode(to: &bitStream)
        try velocity.encode(to: &bitStream)
        try rotation.encode(to: &bitStream)
        bitStream.appendBool(isDestroyed)
        bitStream.appendBool(targeted)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        shipId = try String(from: &bitStream)
        position = try SIMD3<Float>(from: &bitStream)
        velocity = try SIMD3<Float>(from: &bitStream)
        rotation = try simd_quatf(from: &bitStream)
        isDestroyed = try bitStream.readBool()
        targeted = try bitStream.readBool()
    }
}

// MARK: - Missile Synchronization Data

/// Data structure for missile firing events
struct MissileFireData: BitStreamCodable {
    let missileId: String
    let playerId: String
    let startPosition: SIMD3<Float>
    let startRotation: simd_quatf
    let targetShipId: String
    let fireTime: TimeInterval
    
    init(
        missileId: String,
        playerId: String,
        startPosition: SIMD3<Float>,
        startRotation: simd_quatf,
        targetShipId: String,
        fireTime: TimeInterval
    ) {
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
        try startPosition.encode(to: &bitStream)
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

extension WritableBitStream {
    mutating func appendFloat64(_ value: Double) {
        var float = value.bitPattern.littleEndian
        let bytes = withUnsafeBytes(of: &float) { Array($0) }
        appendBytes(bytes)
    }
}

extension ReadableBitStream {
    //    mutating func readFloat64() throws -> Double {
    //        let bytes = try readBytes(count: 8)
    //        let value = bytes.withUnsafeBytes {
    //            $0.load(as: UInt64.self)
    //        }
    //        return Double(bitPattern: UInt64(littleEndian: value))
    //    }
}
/// Data structure for missile position updates
struct MissileSyncData: BitStreamCodable {
    let missileId: String
    let position: SIMD3<Float>
    let rotation: simd_quatf
    let timestamp: TimeInterval
    
    init(
          missileId: String,
          position: SIMD3<Float>,
          rotation: simd_quatf,
          timestamp: TimeInterval
      ) {
          self.missileId = missileId
          self.position = position
          self.rotation = rotation
          self.timestamp = timestamp
      }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try missileId.encode(to: &bitStream)
        try position.encode(to: &bitStream)
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

/// Data structure for missile hit events
struct MissileHitData: BitStreamCodable {
    let missileId: String
    let shipId: String
    let hitPosition: SIMD3<Float>
    let playerId: String
    let timestamp: TimeInterval
    
    init(
        missileId: String,
        shipId: String,
        hitPosition: SIMD3<Float>,
        playerId: String,
        timestamp: TimeInterval
    ) {
        self.missileId = missileId
        self.shipId = shipId
        self.hitPosition = hitPosition
        self.playerId = playerId
        self.timestamp = timestamp
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try missileId.encode(to: &bitStream)
        try shipId.encode(to: &bitStream)
        try hitPosition.encode(to: &bitStream)
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

extension simd_quatf: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let x = try bitStream.readFloat32()
        let y = try bitStream.readFloat32()
        let z = try bitStream.readFloat32()
        let w = try bitStream.readFloat32()
        self.init(ix: x, iy: y, iz: z, r: w)
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try bitStream.appendFloat32(imag.x)
        try bitStream.appendFloat32(imag.y)
        try bitStream.appendFloat32(imag.z)
        try bitStream.appendFloat32(real)
    }
}

extension WritableBitStream {
    mutating func appendFloat32(_ value: Float) throws {
        var bitPattern = value.bitPattern.littleEndian
        let bytes = withUnsafeBytes(of: &bitPattern) { Array($0) }
        appendBytes(bytes)
    }
}
//extension simd_quatf: BitStreamCodable {
//    public init(from bitStream: inout ReadableBitStream) throws {
//        let x = try bitStream.readFloat()
//        let y = try bitStream.readFloat()
//        let z = try bitStream.readFloat()
//        let w = try bitStream.readFloat()
//        self.init(ix: x, iy: y, iz: z, r: w)
//    }
//
//func encode(to bitStream: inout WritableBitStream) throws {
//        try bitStream.appendFloat(ix)
//        try bitStream.appendFloat(iy)
//        try bitStream.appendFloat(iz)
//        try bitStream.appendFloat(real)
//    }
//}
