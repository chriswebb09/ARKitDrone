//
//  ShipSyncData.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/24/25.
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
    
    init(shipId: String, position: SIMD3<Float>, velocity: SIMD3<Float>, rotation: simd_quatf, isDestroyed: Bool, targeted: Bool) {
        self.shipId = shipId
        self.position = position
        self.velocity = velocity
        self.rotation = rotation
        self.isDestroyed = isDestroyed
        self.targeted = targeted
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try shipId.encode(to: &bitStream)
        position.encode(to: &bitStream)
        velocity.encode(to: &bitStream)
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
