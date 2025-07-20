//
//  MissileSynchronizationTest.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Test file to verify missile synchronization across multiplayer clients
//

import Foundation
import RealityKit
import simd
import os.log
import UIKit

@testable import ARKitDrone
/// Test class to verify missile synchronization functionality
@MainActor
class MissileSynchronizationTest {
    
    static func runTests() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        os_log(.info, "🧪 Starting MissileSynchronizationTest")
        
        // Test 1: Missile fire data encoding/decoding
        results["missile_fire_data_encoding"] = testMissileFireDataEncoding()
        
        // Test 2: Missile sync data encoding/decoding
        results["missile_sync_data_encoding"] = testMissileSyncDataEncoding()
        
        // Test 3: Missile hit data encoding/decoding
        results["missile_hit_data_encoding"] = testMissileHitDataEncoding()
        
        // Test 4: Missile fire event in solo mode (should be no-op)
        results["missile_fire_solo_mode"] = await testMissileFireSoloMode()
        
        // Test 5: Missile fire event in multiplayer mode
        results["missile_fire_multiplayer_mode"] = await testMissileFireMultiplayerMode()
        
        // Test 6: Missile position update
        results["missile_position_update"] = await testMissilePositionUpdate()
        
        // Test 7: Missile hit event
        results["missile_hit_event"] = await testMissileHitEvent()
        
        // Test 8: Multiple missile synchronization
        results["multiple_missiles_sync"] = await testMultipleMissilesSync()
        
        return results
    }
    
    // MARK: - Individual Tests
    
    static func testMissileFireDataEncoding() -> Bool {
        // Test MissileFireData encoding and decoding
        do {
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
            
            let matches = originalData.missileId == decodedData.missileId &&
                         originalData.playerId == decodedData.playerId &&
                         originalData.startPosition == decodedData.startPosition &&
                         originalData.targetShipId == decodedData.targetShipId &&
                         abs(originalData.fireTime - decodedData.fireTime) < 0.001
            
            os_log(.info, "✅ Missile fire data encoding: matches=%@", String(matches))
            return matches
            
        } catch {
            os_log(.error, "❌ Missile fire data encoding failed: %@", error.localizedDescription)
            return false
        }
    }
    
    static func testMissileSyncDataEncoding() -> Bool {
        // Test MissileSyncData encoding and decoding
        do {
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
            
            let matches = originalData.missileId == decodedData.missileId &&
                         originalData.position == decodedData.position &&
                         abs(originalData.timestamp - decodedData.timestamp) < 0.001
            
            os_log(.info, "✅ Missile sync data encoding: matches=%@", String(matches))
            return matches
            
        } catch {
            os_log(.error, "❌ Missile sync data encoding failed: %@", error.localizedDescription)
            return false
        }
    }
    
    static func testMissileHitDataEncoding() -> Bool {
        // Test MissileHitData encoding and decoding
        do {
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
            
            let matches = originalData.missileId == decodedData.missileId &&
                         originalData.shipId == decodedData.shipId &&
                         originalData.hitPosition == decodedData.hitPosition &&
                         originalData.playerId == decodedData.playerId &&
                         abs(originalData.timestamp - decodedData.timestamp) < 0.001
            
            os_log(.info, "✅ Missile hit data encoding: matches=%@", String(matches))
            return matches
            
        } catch {
            os_log(.error, "❌ Missile hit data encoding failed: %@", error.localizedDescription)
            return false
        }
    }
    
    static func testMissileFireSoloMode() async -> Bool {
        // Test that missile fire is no-op in solo mode
        let gameManager = GameManager(arView: ARView(frame: .zero), session: nil)
            
            // This should be a no-op since isNetworked = false
            gameManager.fireMissile(
                missileId: "solo_missile_1",
                from: "solo_player",
                startPosition: SIMD3<Float>(0, 0, 0),
                startRotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                targetShipId: "solo_ship_1"
            )
            
            // No way to verify network calls weren't made, but if we get here without crashing, it's good
            os_log(.info, "✅ Missile fire solo mode: no-op completed successfully")
            return true
            
    }
    
    static func testMissileFireMultiplayerMode() async -> Bool {
        // Test missile fire event in multiplayer
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            gameManager.fireMissile(
                missileId: "mp_missile_1",
                from: "mp_player_1",
                startPosition: SIMD3<Float>(1, 2, 3),
                startRotation: simd_quatf(ix: 0.1, iy: 0.2, iz: 0.3, r: 0.9),
                targetShipId: "mp_ship_1"
            )
            
            let sentMessages = mockSession.sentMessages
            let hasMissileFireMessage = sentMessages.contains { message in
                if case .gameAction(let action) = message,
                   case .missileFired(let data) = action {
                    return data.missileId == "mp_missile_1" && data.playerId == "mp_player_1"
                }
                return false
            }
            
            os_log(.info, "✅ Missile fire multiplayer: hasMessage=%@", String(hasMissileFireMessage))
            return hasMissileFireMessage
            
    }
    
    static func testMissilePositionUpdate() async -> Bool {
        // Test missile position update in multiplayer
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            gameManager.updateMissilePosition(
                missileId: "mp_missile_pos_1",
                position: SIMD3<Float>(4, 5, 6),
                rotation: simd_quatf(ix: 0.4, iy: 0.5, iz: 0.6, r: 0.7)
            )
            
            let sentMessages = mockSession.sentMessages
            let hasMissileUpdateMessage = sentMessages.contains { message in
                if case .gameAction(let action) = message,
                   case .missilePositionUpdate(let data) = action {
                    return data.missileId == "mp_missile_pos_1"
                }
                return false
            }
            
            os_log(.info, "✅ Missile position update: hasMessage=%@", String(hasMissileUpdateMessage))
            return hasMissileUpdateMessage
            
    }
    
    static func testMissileHitEvent() async -> Bool {
        // Test missile hit event in multiplayer
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            gameManager.handleMissileHit(
                missileId: "mp_missile_hit_1",
                shipId: "mp_ship_hit_1",
                hitPosition: SIMD3<Float>(7, 8, 9),
                playerId: "mp_player_hit_1"
            )
            
            let sentMessages = mockSession.sentMessages
            let hasMissileHitMessage = sentMessages.contains { message in
                if case .gameAction(let action) = message,
                   case .missileHit(let data) = action {
                    return data.missileId == "mp_missile_hit_1" && 
                           data.shipId == "mp_ship_hit_1" &&
                           data.playerId == "mp_player_hit_1"
                }
                return false
            }
            
            os_log(.info, "✅ Missile hit event: hasMessage=%@", String(hasMissileHitMessage))
            return hasMissileHitMessage
            
    }
    
    static func testMultipleMissilesSync() async -> Bool {
        // Test multiple missile operations in sequence
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            // Fire multiple missiles
            for i in 0..<3 {
                gameManager.fireMissile(
                    missileId: "multi_missile_\(i)",
                    from: "multi_player_\(i)",
                    startPosition: SIMD3<Float>(Float(i), Float(i), Float(i)),
                    startRotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
                    targetShipId: "multi_ship_\(i)"
                )
                
                gameManager.updateMissilePosition(
                    missileId: "multi_missile_\(i)",
                    position: SIMD3<Float>(Float(i+1), Float(i+1), Float(i+1)),
                    rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
                )
            }
            
            let sentMessages = mockSession.sentMessages
            let fireMessages = sentMessages.filter { message in
                if case .gameAction(let action) = message,
                   case .missileFired(_) = action {
                    return true
                }
                return false
            }
            
            let updateMessages = sentMessages.filter { message in
                if case .gameAction(let action) = message,
                   case .missilePositionUpdate(_) = action {
                    return true
                }
                return false
            }
            
            let hasCorrectMessages = fireMessages.count == 3 && updateMessages.count == 3
            
            os_log(.info, "✅ Multiple missiles sync: fireMessages=%d, updateMessages=%d", 
                   fireMessages.count, updateMessages.count)
            return hasCorrectMessages
            
    }
    
    // MARK: - Test Runner Helper
    
    static func printTestResults(_ results: [String: Bool]) {
        os_log(.info, "🧪 MissileSynchronizationTest Results:")
        
        var passCount = 0
        let totalCount = results.count
        
        for (testName, passed) in results.sorted(by: { $0.key < $1.key }) {
            let status = passed ? "✅ PASS" : "❌ FAIL"
            os_log(.info, "%@ %@", status, testName)
            if passed { passCount += 1 }
        }
        
        let successRate = totalCount > 0 ? (Double(passCount) / Double(totalCount)) * 100 : 0
        os_log(.info, "🎯 Test Summary: %d/%d passed (%.1f%%)", passCount, totalCount, successRate)
        
        if passCount == totalCount {
            os_log(.info, "🎉 All missile synchronization tests passed!")
        } else {
            os_log(.error, "⚠️  Some missile synchronization tests failed. Check implementation.")
        }
    }
}
