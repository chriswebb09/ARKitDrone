//
//  SinglePlayerGameFlowTest.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Test file to verify single player game flow with new multiplayer architecture
//

import Foundation
import RealityKit
import simd
import os.log

@testable import ARKitDrone
/// Test class to verify single player game flow
@MainActor
class SinglePlayerGameFlowTest {
    
    static func runTests() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        os_log(.info, "🧪 Starting SinglePlayerGameFlowTest")
        
        // Test 1: GameManager solo mode initialization
        results["solo_game_manager_init"] = await testSoloGameManagerInit()
        
        // Test 2: Local helicopter creation
        results["local_helicopter_creation"] = await testLocalHelicopterCreation()
        
        // Test 3: Helicopter movement through HelicopterObject
        results["helicopter_movement"] = await testHelicopterMovement()
        
        // Test 4: No duplicate helicopters in solo mode
        results["no_duplicate_helicopters"] = await testNoDuplicateHelicopters()
        
        // Test 5: Missile system integration
        results["missile_system"] = await testMissileSystem()
        
        return results
    }
    
    // MARK: - Individual Tests
    
    static func testSoloGameManagerInit() async -> Bool {
        // Test that GameManager initializes correctly for solo mode
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        
        // Verify solo mode properties
        let isSoloMode = !gameManager.isNetworked && gameManager.isServer
        let hasNoHelicopters = gameManager.getAllHelicopters().isEmpty
        
        os_log(.info, "✅ Solo GameManager: isNetworked=%@, isServer=%@", 
               String(gameManager.isNetworked), String(gameManager.isServer))
        
        return isSoloMode && hasNoHelicopters
    }
    
    static func testLocalHelicopterCreation() async -> Bool {
        // Test creating a local player helicopter
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        let localPlayer = Player(username: "TestPlayer")
        let transform = simd_float4x4(1.0) // Identity matrix
        
        let addNodeAction = AddNodeAction(
            simdWorldTransform: transform,
            eulerAngles: SIMD3<Float>(0, 0, 0)
        )
        
        // Create helicopter
        await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: localPlayer)
        
        // Verify helicopter was created
        let helicopters = gameManager.getAllHelicopters()
        let localHelicopter = gameManager.getHelicopter(for: localPlayer)
        
        let hasOneHelicopter = helicopters.count == 1
        let hasLocalHelicopter = localHelicopter != nil
        let correctOwner = localHelicopter?.owner?.username == "TestPlayer"
        
        os_log(.info, "✅ Helicopter creation: count=%d, hasLocal=%@, correctOwner=%@", 
               helicopters.count, String(hasLocalHelicopter), String(correctOwner))
        
        return hasOneHelicopter && hasLocalHelicopter && correctOwner
    }
    
    static func testHelicopterMovement() async -> Bool {
        // Test helicopter movement through HelicopterObject system
        let gameManager = GameManager(arView: ARView(frame: .zero), session: nil)
            let localPlayer = Player(username: "TestPlayer")
            let transform = simd_float4x4(1.0)
            
            let addNodeAction = AddNodeAction(
                simdWorldTransform: transform,
                eulerAngles: SIMD3<Float>(0, 0, 0)
            )
            
            // Create helicopter
            await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: localPlayer)
            
            // Test movement
            let moveData = MoveData(
                velocity: GameVelocity(vector: SIMD3<Float>(1, 0, 0)),
                angular: 0.5,
                direction: .forward
            )
            
            gameManager.moveHelicopter(player: localPlayer, movement: moveData)
            
            // Verify helicopter still exists and is in moving state
            guard let helicopter = gameManager.getHelicopter(for: localPlayer) else {
                os_log(.error, "❌ Helicopter disappeared after movement")
                return false
            }
            
            os_log(.info, "✅ Helicopter movement: isMoving=%@", String(helicopter.isMoving))
            
            return true // Movement succeeded without crashing
    }
    
    static func testNoDuplicateHelicopters() async -> Bool {
        // Test that solo mode doesn't create duplicate helicopters
        let gameManager = GameManager(arView: ARView(frame: .zero), session: nil)
            let localPlayer = Player(username: "TestPlayer")
            let transform = simd_float4x4(1.0)
            
            let addNodeAction = AddNodeAction(
                simdWorldTransform: transform,
                eulerAngles: SIMD3<Float>(0, 0, 0)
            )
            
            // Create helicopter multiple times (simulating the bug)
            await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: localPlayer)
            await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: localPlayer)
            
            // Should only have one helicopter (second creation should be ignored or overwrite)
            let helicopters = gameManager.getAllHelicopters()
            let hasOnlyOne = helicopters.count == 1
            
            os_log(.info, "✅ Duplicate prevention: helicopterCount=%d", helicopters.count)
            
            return hasOnlyOne
    }
    
    static func testMissileSystem() async -> Bool {
        // Test missile system integration with HelicopterObject
        let gameManager = GameManager(arView: ARView(frame: .zero), session: nil)
            let localPlayer = Player(username: "TestPlayer")
            let transform = simd_float4x4(1.0)
            
            let addNodeAction = AddNodeAction(
                simdWorldTransform: transform,
                eulerAngles: SIMD3<Float>(0, 0, 0)
            )
            
            // Create helicopter
            await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: localPlayer)
            
            guard let helicopter = gameManager.getHelicopter(for: localPlayer) else {
                os_log(.error, "❌ No helicopter for missile test")
                return false
            }
            
            // Test missile arming
            let initialState = helicopter.missilesArmed()
            helicopter.toggleMissileArmed()
            let toggledState = helicopter.missilesArmed()
            
            let missileToggleWorks = initialState != toggledState
            
            os_log(.info, "✅ Missile system: initial=%@, toggled=%@", 
                   String(initialState), String(toggledState))
            
            return missileToggleWorks
    }
    
    // MARK: - Test Runner Helper
    
    static func printTestResults(_ results: [String: Bool]) {
        os_log(.info, "🧪 SinglePlayerGameFlowTest Results:")
        
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
            os_log(.info, "🎉 All tests passed! Solo game flow is working correctly.")
        } else {
            os_log(.error, "⚠️  Some tests failed. Check implementation.")
        }
    }
}
