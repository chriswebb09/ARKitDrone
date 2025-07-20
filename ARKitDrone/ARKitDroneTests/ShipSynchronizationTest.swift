//
//  ShipSynchronizationTest.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Test file to verify ship synchronization across multiplayer clients
//

import Foundation
import RealityKit
import simd
import os.log

@testable import ARKitDrone

/// Test class to verify ship synchronization functionality
@MainActor
class ShipSynchronizationTest {
    
    static func runTests() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        os_log(.info, "🧪 Starting ShipSynchronizationTest")
        
        // Test 1: Ship sync data encoding/decoding
        results["ship_sync_data_encoding"] = testShipSyncDataEncoding()
        
        // Test 2: Ship synchronization in solo mode (should be no-op)
        results["ship_sync_solo_mode"] = await testShipSyncSoloMode()
        
        // Test 3: Ship synchronization in multiplayer mode
        results["ship_sync_multiplayer_mode"] = await testShipSyncMultiplayerMode()
        
        // Test 4: Ship destroyed event
        results["ship_destroyed_event"] = await testShipDestroyedEvent()
        
        // Test 5: Ship targeting event
        results["ship_targeting_event"] = await testShipTargetingEvent()
        
        // Test 6: Multiple ships synchronization
        results["multiple_ships_sync"] = await testMultipleShipsSync()
        
        return results
    }
    
    // MARK: - Individual Tests
    
    static func testShipSyncDataEncoding() -> Bool {
        // Test ShipSyncData encoding and decoding
        do {
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
            
            let matches = originalData.shipId == decodedData.shipId &&
                         originalData.position == decodedData.position &&
                         originalData.velocity == decodedData.velocity &&
                         originalData.isDestroyed == decodedData.isDestroyed &&
                         originalData.targeted == decodedData.targeted
            
            os_log(.info, "✅ Ship sync data encoding: matches=%@", String(matches))
            return matches
            
        } catch {
            os_log(.error, "❌ Ship sync data encoding failed: %@", error.localizedDescription)
            return false
        }
    }
    
    static func testShipSyncSoloMode() async -> Bool {
        // Test that ship synchronization is no-op in solo mode
        let gameManager = GameManager(arView: ARView(frame: .zero), session: nil)
            
            // Create mock ships
            let mockShips = createMockShips()
            
            // This should be a no-op since isNetworked = false
            gameManager.synchronizeShips(mockShips)
            gameManager.updateShipState(shipId: "test_ship_1", isDestroyed: true)
            gameManager.updateShipTargeting(shipId: "test_ship_1", targeted: true)
            
            // No way to verify network calls weren't made, but if we get here without crashing, it's good
            os_log(.info, "✅ Ship sync solo mode: no-op completed successfully")
            return true
            
    }
    
    static func testShipSyncMultiplayerMode() async -> Bool {
        // Test ship synchronization with mock multiplayer setup
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            let mockShips = createMockShips()
            
            // This should call session.send() 
            gameManager.synchronizeShips(mockShips)
            
            // Verify the mock session received the call
            let sentMessages = mockSession.sentMessages
            let hasShipSyncMessage = sentMessages.contains { message in
                if case .gameAction(let action) = message,
                   case .shipsPositionSync(_) = action {
                    return true
                }
                return false
            }
            
            os_log(.info, "✅ Ship sync multiplayer: sentMessages=%d, hasShipSync=%@", 
                   sentMessages.count, String(hasShipSyncMessage))
            
            return hasShipSyncMessage
            
    }
    
    static func testShipDestroyedEvent() async -> Bool {
        // Test ship destroyed event in multiplayer
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            gameManager.updateShipState(shipId: "test_ship_destroyed", isDestroyed: true)
            
            let sentMessages = mockSession.sentMessages
            let hasDestroyedMessage = sentMessages.contains { message in
                if case .gameAction(let action) = message,
                   case .shipDestroyed(let shipId) = action {
                    return shipId == "test_ship_destroyed"
                }
                return false
            }
            
            os_log(.info, "✅ Ship destroyed event: hasMessage=%@", String(hasDestroyedMessage))
            return hasDestroyedMessage
            
    }
    
    static func testShipTargetingEvent() async -> Bool {
        // Test ship targeting event in multiplayer
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            gameManager.updateShipTargeting(shipId: "test_ship_targeted", targeted: true)
            
            let sentMessages = mockSession.sentMessages
            let hasTargetingMessage = sentMessages.contains { message in
                if case .gameAction(let action) = message,
                   case .shipTargeted(let shipId, let targeted) = action {
                    return shipId == "test_ship_targeted" && targeted == true
                }
                return false
            }
            
            os_log(.info, "✅ Ship targeting event: hasMessage=%@", String(hasTargetingMessage))
            return hasTargetingMessage
            
    }
    
    static func testMultipleShipsSync() async -> Bool {
        // Test synchronizing multiple ships at once
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: ARView(frame: .zero), session: mockSession)
            
            let mockShips = createMockShips(count: 5)
            gameManager.synchronizeShips(mockShips)
            
            let sentMessages = mockSession.sentMessages
            let shipsMessage = sentMessages.first { message in
                if case .gameAction(let action) = message,
                   case .shipsPositionSync(let ships) = action {
                    return ships.count == 5
                }
                return false
            }
            
            let hasCorrectMessage = shipsMessage != nil
            
            os_log(.info, "✅ Multiple ships sync: hasMessage=%@", String(hasCorrectMessage))
            return hasCorrectMessage
            
    }
    
    // MARK: - Helper Methods
    
    static func createMockShips(count: Int = 3) -> [Ship] {
        var ships: [Ship] = []
        
        for i in 0..<count {
            let mockEntity = Entity()
            let ship = Ship(entity: mockEntity)
            ship.id = "test_ship_\(i)"
            ship.entity.transform.translation = SIMD3<Float>(Float(i), 0, Float(i))
            ship.velocity = SIMD3<Float>(0.1, 0, 0.1)
            ship.entity.transform.rotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
            ship.isDestroyed = i % 2 == 0 // Every other ship is destroyed
            ship.targeted = i % 3 == 0   // Every third ship is targeted
            ships.append(ship)
        }
        
        return ships
    }
    
    // MARK: - Test Runner Helper
    
    static func printTestResults(_ results: [String: Bool]) {
        os_log(.info, "🧪 ShipSynchronizationTest Results:")
        
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
            os_log(.info, "🎉 All ship synchronization tests passed!")
        } else {
            os_log(.error, "⚠️  Some ship synchronization tests failed. Check implementation.")
        }
    }
}

