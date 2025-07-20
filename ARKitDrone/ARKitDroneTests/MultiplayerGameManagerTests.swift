//
//  MultiplayerGameManagerTests.swift
//  ARKitDroneTests
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Testing
import Foundation
import simd
import RealityKit
@testable import ARKitDrone

@MainActor
struct MultiplayerGameManagerTests {
    
    @Test("GameManager initializes correctly for solo mode")
    func testSoloModeInitialization() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        
        #expect(!gameManager.isNetworked)
        #expect(gameManager.isServer)
        #expect(gameManager.getAllHelicopters().isEmpty)
    }
    
    @Test("GameManager initializes correctly for multiplayer mode")
    func testMultiplayerModeInitialization() async throws {
        let mockARView = ARView(frame: .zero)
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: mockARView, session: mockSession)
        
        #expect(gameManager.isNetworked)
        #expect(gameManager.isServer)
        #expect(gameManager.getAllHelicopters().isEmpty)
    }
    
    @Test("Ship synchronization calls are no-op in solo mode")
    func testShipSyncSoloMode() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        let mockShips = createMockShips()
        
        // These should be no-ops and not crash
        gameManager.synchronizeShips(mockShips)
        gameManager.updateShipState(shipId: "test_ship", isDestroyed: true)
        gameManager.updateShipTargeting(shipId: "test_ship", targeted: true)
        
        // If we get here without crashing, the test passes
    }
    
    @Test("Missile synchronization calls are no-op in solo mode")
    func testMissileSyncSoloMode() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        
        // These should be no-ops and not crash
        gameManager.fireMissile(
            missileId: "test_missile",
            from: "test_player",
            startPosition: SIMD3<Float>(0, 0, 0),
            startRotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1),
            targetShipId: "test_ship"
        )
        
        gameManager.updateMissilePosition(
            missileId: "test_missile",
            position: SIMD3<Float>(1, 1, 1),
            rotation: simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
        )
        
        gameManager.handleMissileHit(
            missileId: "test_missile",
            shipId: "test_ship",
            hitPosition: SIMD3<Float>(2, 2, 2),
            playerId: "test_player"
        )
        
        // If we get here without crashing, the test passes
    }
    
    @Test("Ship synchronization sends network messages in multiplayer mode")
    func testShipSyncMultiplayerMode() async throws {
        let mockARView = ARView(frame: .zero)
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: mockARView, session: mockSession)
        let mockShips = createMockShips()
        
        gameManager.synchronizeShips(mockShips)
        
        let sentMessages = mockSession.sentMessages
        let hasShipSyncMessage = sentMessages.contains { message in
            if case .gameAction(let action) = message,
               case .shipsPositionSync(let ships) = action {
                return ships.count == mockShips.count
            }
            return false
        }
        
        #expect(hasShipSyncMessage)
    }
    
    @Test("Missile fire sends network message in multiplayer mode")
    func testMissileFireMultiplayerMode() async throws {
        let mockARView = ARView(frame: .zero)
        let mockSession = MockNetworkSession(isServer: true)
        let gameManager = GameManager(arView: mockARView, session: mockSession)
        
        gameManager.fireMissile(
            missileId: "mp_missile",
            from: "mp_player",
            startPosition: SIMD3<Float>(1, 2, 3),
            startRotation: simd_quatf(ix: 0.1, iy: 0.2, iz: 0.3, r: 0.9),
            targetShipId: "mp_ship"
        )
        
        let sentMessages = mockSession.sentMessages
        let hasMissileFireMessage = sentMessages.contains { message in
            if case .gameAction(let action) = message,
               case .missileFired(let data) = action {
                return data.missileId == "mp_missile" && data.playerId == "mp_player"
            }
            return false
        }
        
        #expect(hasMissileFireMessage)
    }
    
    @Test("Helicopter creation works correctly")
    func testHelicopterCreation() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        let player = Player(username: "TestPlayer")
        let transform = simd_float4x4(1.0) // Identity matrix
        
        let addNodeAction = AddNodeAction(
            simdWorldTransform: transform,
            eulerAngles: SIMD3<Float>(0, 0, 0)
        )
        
        await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: player)
        
        let helicopters = gameManager.getAllHelicopters()
        let playerHelicopter = gameManager.getHelicopter(for: player)
        
        #expect(helicopters.count == 1)
        #expect(playerHelicopter != nil)
        #expect(playerHelicopter?.owner?.username == "TestPlayer")
    }
    
    @Test("Helicopter movement updates correctly")
    func testHelicopterMovement() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        let player = Player(username: "TestPlayer")
        let transform = simd_float4x4(1.0)
        
        let addNodeAction = AddNodeAction(
            simdWorldTransform: transform,
            eulerAngles: SIMD3<Float>(0, 0, 0)
        )
        
        await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: player)
        
        let moveData = MoveData(
            velocity: GameVelocity(vector: SIMD3<Float>(1, 0, 0)),
            angular: 0.5,
            direction: .forward
        )
        
        gameManager.moveHelicopter(player: player, movement: moveData)
        
        // Verify helicopter still exists and movement was processed
        let helicopter = gameManager.getHelicopter(for: player)
        #expect(helicopter != nil)
    }
    
    @Test("Helicopter removal works correctly")
    func testHelicopterRemoval() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        let player = Player(username: "TestPlayer")
        let transform = simd_float4x4(1.0)
        
        let addNodeAction = AddNodeAction(
            simdWorldTransform: transform,
            eulerAngles: SIMD3<Float>(0, 0, 0)
        )
        
        await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: player)
        
        // Verify helicopter was created
        #expect(gameManager.getAllHelicopters().count == 1)
        #expect(gameManager.getHelicopter(for: player) != nil)
        
        // Remove helicopter
        gameManager.removeHelicopter(for: player)
        
        // Verify helicopter was removed
        #expect(gameManager.getAllHelicopters().count == 0)
        #expect(gameManager.getHelicopter(for: player) == nil)
    }
    
    @Test("Multiple helicopters can be tracked")
    func testMultipleHelicopters() async throws {
        let mockARView = ARView(frame: .zero)
        let gameManager = GameManager(arView: mockARView, session: nil)
        let player1 = Player(username: "Player1")
        let player2 = Player(username: "Player2")
        let transform = simd_float4x4(1.0)
        
        let addNodeAction = AddNodeAction(
            simdWorldTransform: transform,
            eulerAngles: SIMD3<Float>(0, 0, 0)
        )
        
        await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: player1)
        await gameManager.createHelicopter(addNodeAction: addNodeAction, owner: player2)
        
        let helicopters = gameManager.getAllHelicopters()
        #expect(helicopters.count == 2)
        #expect(gameManager.getHelicopter(for: player1) != nil)
        #expect(gameManager.getHelicopter(for: player2) != nil)
    }
    
    // MARK: - Helper Methods
    
    private func createMockShips(count: Int = 3) -> [Ship] {
        var ships: [Ship] = []
        
        for i in 0..<count {
            let mockEntity = Entity()
            let ship = Ship(entity: mockEntity)
            ship.id = "test_ship_\(i)"
            ship.entity.transform.translation = SIMD3<Float>(Float(i), 0, Float(i))
            ship.velocity = SIMD3<Float>(0.1, 0, 0.1)
            ship.entity.transform.rotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
            ship.isDestroyed = i % 2 == 0
            ship.targeted = i % 3 == 0
            ships.append(ship)
        }
        
        return ships
    }
}

// MARK: - Mock Network Session

class MockNetworkSession: NetworkSession {
    private(set) var sentMessages: [Action] = []
    
    init(isServer: Bool) {
        let mockPlayer = Player(username: "MockPlayer")
        let mockHost = Player(username: "MockHost")
        super.init(myself: mockPlayer, asServer: isServer, host: mockHost)
    }
    
    
    override func send(action: Action) {
        sentMessages.append(action)
    }
    
    override func send(action: Action, to player: Player) {
        sentMessages.append(action)
    }
    
    override func startAdvertising() {
        // Mock implementation
    }
}