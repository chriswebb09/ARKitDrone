//
//  BitStreamDataStructureTests.swift
//  ARKitDroneTests
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Testing
import Foundation
import simd
import UIKit

@testable import ARKitDrone

struct BitStreamDataStructureTests {
    
    @Test("ShipSyncData encoding and decoding preserves all data")
    func testShipSyncDataEncoding() throws {
        let originalData = ShipSyncData(
            shipId: "test_ship_123",
            position: SIMD3<Float>(1.5, 2.0, 3.5),
            velocity: SIMD3<Float>(0.1, 0.0, 0.2),
            rotation: simd_quatf(ix: 0.1, iy: 0.2, iz: 0.3, r: 0.9),
            isDestroyed: false,
            targeted: true
        )
        
        var writeStream = WritableBitStream()
        try originalData.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedData = try ShipSyncData(from: &readStream)
        
        #expect(originalData.shipId == decodedData.shipId)
        #expect(originalData.position == decodedData.position)
        #expect(originalData.velocity == decodedData.velocity)
        #expect(originalData.isDestroyed == decodedData.isDestroyed)
        #expect(originalData.targeted == decodedData.targeted)
        
        // Check quaternion components individually due to floating point precision
        #expect(abs(originalData.rotation.imag.x - decodedData.rotation.imag.x) < 0.001)
        #expect(abs(originalData.rotation.imag.y - decodedData.rotation.imag.y) < 0.001)
        #expect(abs(originalData.rotation.imag.z - decodedData.rotation.imag.z) < 0.001)
        #expect(abs(originalData.rotation.real - decodedData.rotation.real) < 0.001)
    }
    
    @Test("MissileFireData encoding and decoding preserves all data")
    func testMissileFireDataEncoding() throws {
        let originalData = MissileFireData(
            missileId: "missile_123",
            playerId: "player_456",
            startPosition: SIMD3<Float>(1.0, 2.0, 3.0),
            startRotation: simd_quatf(ix: 0.1, iy: 0.2, iz: 0.3, r: 0.9),
            targetShipId: "ship_789",
            fireTime: CACurrentMediaTime()
        )
        
        var writeStream = WritableBitStream()
        try originalData.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedData = try MissileFireData(from: &readStream)
        
        #expect(originalData.missileId == decodedData.missileId)
        #expect(originalData.playerId == decodedData.playerId)
        #expect(originalData.startPosition == decodedData.startPosition)
        #expect(originalData.targetShipId == decodedData.targetShipId)
        #expect(abs(originalData.fireTime - decodedData.fireTime) < 0.001)
        
        // Check quaternion components
        #expect(abs(originalData.startRotation.imag.x - decodedData.startRotation.imag.x) < 0.001)
        #expect(abs(originalData.startRotation.imag.y - decodedData.startRotation.imag.y) < 0.001)
        #expect(abs(originalData.startRotation.imag.z - decodedData.startRotation.imag.z) < 0.001)
        #expect(abs(originalData.startRotation.real - decodedData.startRotation.real) < 0.001)
    }
    
    @Test("MissileSyncData encoding and decoding preserves all data")
    func testMissileSyncDataEncoding() throws {
        let originalData = MissileSyncData(
            missileId: "missile_sync_123",
            position: SIMD3<Float>(5.0, 6.0, 7.0),
            rotation: simd_quatf(ix: 0.4, iy: 0.5, iz: 0.6, r: 0.7),
            timestamp: CACurrentMediaTime()
        )
        
        var writeStream = WritableBitStream()
        try originalData.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedData = try MissileSyncData(from: &readStream)
        
        #expect(originalData.missileId == decodedData.missileId)
        #expect(originalData.position == decodedData.position)
        #expect(abs(originalData.timestamp - decodedData.timestamp) < 0.001)
        
        // Check quaternion components
        #expect(abs(originalData.rotation.imag.x - decodedData.rotation.imag.x) < 0.001)
        #expect(abs(originalData.rotation.imag.y - decodedData.rotation.imag.y) < 0.001)
        #expect(abs(originalData.rotation.imag.z - decodedData.rotation.imag.z) < 0.001)
        #expect(abs(originalData.rotation.real - decodedData.rotation.real) < 0.001)
    }
    
    @Test("MissileHitData encoding and decoding preserves all data")
    func testMissileHitDataEncoding() throws {
        let originalData = MissileHitData(
            missileId: "missile_hit_123",
            shipId: "ship_hit_456",
            hitPosition: SIMD3<Float>(8.0, 9.0, 10.0),
            playerId: "player_hit_789",
            timestamp: CACurrentMediaTime()
        )
        
        var writeStream = WritableBitStream()
        try originalData.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedData = try MissileHitData(from: &readStream)
        
        #expect(originalData.missileId == decodedData.missileId)
        #expect(originalData.shipId == decodedData.shipId)
        #expect(originalData.hitPosition == decodedData.hitPosition)
        #expect(originalData.playerId == decodedData.playerId)
        #expect(abs(originalData.timestamp - decodedData.timestamp) < 0.001)
    }
    
    @Test("GameAction encoding and decoding works for ship sync")
    func testGameActionShipSync() throws {
        let shipData = [
            ShipSyncData(
                shipId: "ship_1",
                position: SIMD3<Float>(1, 2, 3),
                velocity: SIMD3<Float>(0.1, 0, 0.2),
                rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                isDestroyed: false,
                targeted: true
            ),
            ShipSyncData(
                shipId: "ship_2",
                position: SIMD3<Float>(4, 5, 6),
                velocity: SIMD3<Float>(0.2, 0, 0.1),
                rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                isDestroyed: true,
                targeted: false
            )
        ]
        
        let originalAction = GameAction.shipsPositionSync(shipData)
        
        var writeStream = WritableBitStream()
        try originalAction.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedAction = try GameAction(from: &readStream)
        
        if case .shipsPositionSync(let decodedShips) = decodedAction {
            #expect(decodedShips.count == 2)
            #expect(decodedShips[0].shipId == "ship_1")
            #expect(decodedShips[1].shipId == "ship_2")
            #expect(decodedShips[0].targeted == true)
            #expect(decodedShips[1].isDestroyed == true)
        } else {
            Issue.record("Decoded action is not .shipsPositionSync")
        }
    }
    
    @Test("GameAction encoding and decoding works for missile fire")
    func testGameActionMissileFire() throws {
        let missileData = MissileFireData(
            missileId: "test_missile",
            playerId: "test_player",
            startPosition: SIMD3<Float>(1, 2, 3),
            startRotation: simd_quatf(ix: 0.1, iy: 0.2, iz: 0.3, r: 0.9),
            targetShipId: "test_ship",
            fireTime: 123.456
        )
        
        let originalAction = GameAction.missileFired(missileData)
        
        var writeStream = WritableBitStream()
        try originalAction.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedAction = try GameAction(from: &readStream)
        
        if case .missileFired(let decodedData) = decodedAction {
            #expect(decodedData.missileId == "test_missile")
            #expect(decodedData.playerId == "test_player")
            #expect(decodedData.targetShipId == "test_ship")
            #expect(abs(decodedData.fireTime - 123.456) < 0.001)
        } else {
            Issue.record("Decoded action is not .missileFired")
        }
    }
    
    @Test("simd_quatf BitStreamCodable implementation works correctly")
    func testQuaternionEncoding() throws {
        let originalQuat = simd_quatf(ix: 0.1, iy: 0.2, iz: 0.3, r: 0.9)
        
        var writeStream = WritableBitStream()
        try originalQuat.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedQuat = try simd_quatf(from: &readStream)
        
        #expect(abs(originalQuat.imag.x - decodedQuat.imag.x) < 0.001)
        #expect(abs(originalQuat.imag.y - decodedQuat.imag.y) < 0.001)
        #expect(abs(originalQuat.imag.z - decodedQuat.imag.z) < 0.001)
        #expect(abs(originalQuat.real - decodedQuat.real) < 0.001)
    }
    
    @Test("Array of BitStreamCodable items encodes and decodes correctly")
    func testArrayEncoding() throws {
        let originalShips = [
            ShipSyncData(
                shipId: "ship_1",
                position: SIMD3<Float>(1, 2, 3),
                velocity: SIMD3<Float>(0.1, 0, 0.2),
                rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                isDestroyed: false,
                targeted: true
            ),
            ShipSyncData(
                shipId: "ship_2",
                position: SIMD3<Float>(4, 5, 6),
                velocity: SIMD3<Float>(0.2, 0, 0.1),
                rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                isDestroyed: true,
                targeted: false
            )
        ]
        
        var writeStream = WritableBitStream()
        try originalShips.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedShips = try [ShipSyncData](from: &readStream)
        
        #expect(decodedShips.count == 2)
        #expect(decodedShips[0].shipId == "ship_1")
        #expect(decodedShips[1].shipId == "ship_2")
        #expect(decodedShips[0].targeted == true)
        #expect(decodedShips[1].isDestroyed == true)
    }
    
    @Test("Empty array encodes and decodes correctly")
    func testEmptyArrayEncoding() throws {
        let originalShips: [ShipSyncData] = []
        
        var writeStream = WritableBitStream()
        try originalShips.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedShips = try [ShipSyncData](from: &readStream)
        
        #expect(decodedShips.isEmpty)
    }
    
    @Test("Large array encodes and decodes correctly")
    func testLargeArrayEncoding() throws {
        var originalShips: [ShipSyncData] = []
        
        for i in 0..<100 {
            let ship = ShipSyncData(
                shipId: "ship_\(i)",
                position: SIMD3<Float>(Float(i), Float(i), Float(i)),
                velocity: SIMD3<Float>(0.1, 0, 0.1),
                rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                isDestroyed: i % 2 == 0,
                targeted: i % 3 == 0
            )
            originalShips.append(ship)
        }
        
        var writeStream = WritableBitStream()
        try originalShips.encode(to: &writeStream)
        
        var readStream = ReadableBitStream(data: writeStream.packData())
        let decodedShips = try [ShipSyncData](from: &readStream)
        
        #expect(decodedShips.count == 100)
        #expect(decodedShips[0].shipId == "ship_0")
        #expect(decodedShips[99].shipId == "ship_99")
        #expect(decodedShips[50].isDestroyed == true) // 50 % 2 == 0
        #expect(decodedShips[51].targeted == true)   // 51 % 3 == 0
    }
}
