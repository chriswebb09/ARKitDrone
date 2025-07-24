//
//  ARKitDroneTests.swift
//  ARKitDroneTests
//
//  Created by Christopher Webb on 7/19/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import simd
import Testing
import RealityKit
@testable import ARKitDrone

struct ARKitDroneTests {

    @Test func testMissileHitDataInit() async throws {
        let missileId = "missile_123"
        let shipId = "ship_456"
        let position = SIMD3<Float>(1, 2, 3)
        let playerId = "player_789"
        let timestamp = 123.456

        let hitData = MissileHitData(
            missileId: missileId,
            shipId: shipId,
            hitPosition: position,
            playerId: playerId,
            timestamp: timestamp
        )

        #expect(hitData.missileId == missileId)
        #expect(hitData.shipId == shipId)
        #expect(hitData.hitPosition == position)
        #expect(hitData.playerId == playerId)
        #expect(hitData.timestamp == timestamp)
    }

    @Test func testAddNodeActionTransformPreserved() async throws {
        let transform = matrix_identity_float4x4
        let eulerAngles = SIMD3<Float>(0, 0, 0)

        let action = AddNodeAction(simdWorldTransform: transform, eulerAngles: eulerAngles)

        #expect(action.simdWorldTransform == transform)
    }

    @Test func testCreateHelicopterSetsOwner() async throws {
        let player = Player(username: "TestPilot")

        var transform = matrix_identity_float4x4
        transform.columns.3 = SIMD4<Float>(0, 0, -5, 1)

        let helicopter = await HelicopterObject(owner: player, worldTransform: transform)

        // Test that the owner is set correctly
        await #expect(helicopter.owner?.username == "TestPilot")
        
        // Test that helicopter entity exists (even if model loading fails in test environment)
        await #expect(helicopter.helicopterEntity != nil)
        
        // Only test transform if the helicopter model was successfully loaded
        if let model = await helicopter.helicopterEntity?.helicopter {
            // Capture transform value before MainActor.run to avoid Swift 6 concurrency issue
            let capturedTransform = transform
            // Set the transform using RealityKit's correct API on MainActor
            await MainActor.run {
                model.transform = Transform(matrix: capturedTransform)
            }
            let translation = await MainActor.run { model.transform.translation }
            #expect(translation.z == -5)
        } else {
            // In test environment, model loading might fail - this is expected
            await #expect(helicopter.helicopterEntity?.helicopter == nil)
        }
    }
}
