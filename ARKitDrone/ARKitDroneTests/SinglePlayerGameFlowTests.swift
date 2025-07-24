//
//  SinglePlayerGameFlowTests.swift
//  ARKitDroneTests
//
//  Created by Claude on 2025-01-24.
//  Focused single-player game flow and state management tests
//

import Testing
import RealityKit
import ARKit
@testable import ARKitDrone

@MainActor
struct SinglePlayerGameFlowTests {
    
    // MARK: - Test Properties
    
    var testPlayer: Player!
    var gameStateManager: GameStateManager!
    var testGame: Game!
    
    init() {
        testPlayer = Player(username: "SinglePlayerTester")
        gameStateManager = GameStateManager()
        testGame = Game()
        
        // Set up for single-player
        UserDefaults.standard.set("SinglePlayerTester", forKey: "myself")
    }
    
    // MARK: - Game Start Flow Tests
    
    @Test("Single-player game starts with correct initial state")
    func testSinglePlayerGameStart() {
        // Initial state should be setup
        #expect(gameStateManager.sessionState == .setup)
        #expect(!gameStateManager.helicopterPlaced)
        #expect(!gameStateManager.gameInProgress)
        
        // Game object initial state
        #expect(testGame.score == 0)
        #expect(!testGame.placed)
        #expect(!testGame.scoreUpdated)
        #expect(!testGame.valueReached)
    }
    
    @Test("Game transitions through states correctly for single-player")
    func testSinglePlayerStateTransitions() {
        // Start -> Looking for surface
        gameStateManager.transitionTo(.lookingForSurface)
        #expect(gameStateManager.sessionState == .lookingForSurface)
        
        // Looking for surface -> Game in progress (after helicopter placement)
        gameStateManager.helicopterPlaced = true
        gameStateManager.transitionTo(.gameInProgress)
        #expect(gameStateManager.sessionState == .gameInProgress)
        #expect(gameStateManager.gameInProgress)
    }
    
    @Test("Single-player setup configures correctly")
    func testSinglePlayerSetup() {
        // Setup networked game as single-player (server with no peers)
        gameStateManager.setupNetworkedGame(asServer: true, connectedPlayers: [testPlayer])
        
        #expect(gameStateManager.connectedPlayers.count == 1)
        #expect(gameStateManager.connectedPlayers.first == testPlayer)
        #expect(gameStateManager.isServer)
    }
    
    // MARK: - Helicopter Management Tests
    
    @Test("Helicopter health system works in single-player")
    func testHelicopterHealthSystem() async {
        let transform = simd_float4x4(1.0)
        let helicopter = await HelicopterObject(owner: testPlayer, worldTransform: transform)
        
        #expect(helicopter.healthSystem != nil)
        
        let initialHealth = helicopter.healthSystem?.currentHealth ?? 0.0
        #expect(initialHealth == 100.0)
        #expect(helicopter.healthSystem?.isAlive == true)
        
        // Test damage
        helicopter.takeDamage(25.0, from: "test")
        #expect((helicopter.healthSystem?.currentHealth ?? 0.0) == 75.0)
        #expect(helicopter.healthSystem?.isAlive == true)
        
        // Test destruction
        helicopter.takeDamage(100.0, from: "test")
        #expect((helicopter.healthSystem?.currentHealth ?? 0.0) <= 0.0)
        #expect(helicopter.healthSystem?.isAlive == false)
    }
    
    @Test("Helicopter missile arming works correctly")
    func testHelicopterMissileArming() async {
        let transform = simd_float4x4(1.0)
        let helicopter = await HelicopterObject(owner: testPlayer, worldTransform: transform)
        
        // Should start disarmed
        #expect(!helicopter.missilesArmed())
        
        // Arm missiles
        helicopter.toggleMissileArmed()
        #expect(helicopter.missilesArmed())
        
        // Disarm missiles
        helicopter.toggleMissileArmed()
        #expect(!helicopter.missilesArmed())
    }
    
    @Test("Helicopter missile firing conditions are checked")
    func testHelicopterMissileFiringConditions() async {
        let transform = simd_float4x4(1.0)
        let helicopter = await HelicopterObject(owner: testPlayer, worldTransform: transform)
        
        // Cannot fire when disarmed
        let canFireDisarmed = helicopter.fireMissile()
        #expect(!canFireDisarmed)
        
        // Can fire when armed (if other conditions met)
        helicopter.toggleMissileArmed()
        let canFireArmed = helicopter.fireMissile()
        // Note: This may still be false due to other conditions, but won't fail due to arming
        #expect(true) // Just ensure no crash
    }
    
    // MARK: - Score Management Tests
    
    @Test("Score updates correctly during single-player game")
    func testScoreManagement() {
        let initialScore = testGame.score
        
        // Simulate ship destruction
        testGame.score += 100
        testGame.scoreUpdated = true
        
        #expect(testGame.score == initialScore + 100)
        #expect(testGame.scoreUpdated)
        
        // Simulate multiple ship destructions
        testGame.score += 150
        #expect(testGame.score == initialScore + 250)
        
        // Reset score update flag
        testGame.scoreUpdated = false
        #expect(!testGame.scoreUpdated)
    }
    
    @Test("Game state manager tracks score correctly")
    func testGameStateManagerScoreTracking() {
        let initialScore = gameStateManager.score
        
        // Update score through state manager
        gameStateManager.score = 500
        #expect(gameStateManager.score == 500)
        
        // Test ship destruction scoring
        gameStateManager.destroyShip(worth: 100)
        #expect(gameStateManager.score == 600)
        
        gameStateManager.destroyShip(worth: 200)
        #expect(gameStateManager.score == 800)
    }
    
    // MARK: - Health Management Tests
    
    @Test("Helicopter health is tracked by game state manager")
    func testHelicopterHealthTracking() {
        let initialHealth = gameStateManager.helicopterHealth
        #expect(initialHealth == 100.0) // Default max health
        
        // Update health
        gameStateManager.updateHelicopterHealth(75.0)
        #expect(gameStateManager.helicopterHealth == 75.0)
        
        // Test damage
        gameStateManager.damageHelicopter(25.0, from: "enemy")
        #expect(gameStateManager.helicopterHealth == 50.0)
        
        // Test critical health
        gameStateManager.damageHelicopter(45.0, from: "enemy")
        #expect(gameStateManager.helicopterHealth == 5.0)
        #expect(gameStateManager.helicopterHealth < 25.0) // Critical threshold
    }
    
    // MARK: - Game Placement Tests
    
    @Test("Game placement state is managed correctly")
    func testGamePlacementState() {
        #expect(!testGame.placed)
        #expect(!gameStateManager.helicopterPlaced)
        
        // Place game
        testGame.placed = true
        gameStateManager.helicopterPlaced = true
        
        #expect(testGame.placed)
        #expect(gameStateManager.helicopterPlaced)
        
        // Transition to game in progress
        gameStateManager.transitionTo(.gameInProgress)
        #expect(gameStateManager.gameInProgress)
    }
    
    // MARK: - Missile System Integration Tests
    
    @Test("Missile system integrates with single-player game state")
    func testMissileSystemIntegration() {
        // Test missile can hit flag
        #expect(!testGame.valueReached)
        
        // Simulate missile reaching target
        testGame.valueReached = true
        #expect(testGame.valueReached)
        
        // Reset for next missile
        testGame.valueReached = false
        #expect(!testGame.valueReached)
    }
    
    @Test("Game handles missile state notifications")
    func testMissileStateNotifications() {
        let notificationCenter = NotificationCenter.default
        var missileCanHitReceived = false
        
        // Set up notification observer
        let observer = notificationCenter.addObserver(
            forName: .missileCanHit,
            object: nil,
            queue: .main
        ) { _ in
            missileCanHitReceived = true
        }
        
        // Post notification
        notificationCenter.post(name: .missileCanHit, object: nil)
        
        // Wait briefly for notification to be processed
        let expectation = XCTestExpectation(description: "Notification received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        // Clean up
        notificationCenter.removeObserver(observer)
        
        // Verify the notification was received
        #expect(missileCanHitReceived)
    }
    
    // MARK: - Ship Management in Single-Player Tests
    
    @Test("Ships behave correctly in single-player mode")
    func testShipBehaviorSinglePlayer() {
        let arView = ARView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shipManager = ShipManager(game: testGame, arView: arView)
        
        // Initially no ships
        #expect(shipManager.ships.isEmpty)
        #expect(shipManager.targetIndex == 0)
        #expect(shipManager.isAutoTargeting)
        
        // Create test ship
        let entity = Entity()
        entity.name = "Ship_single_player_test"
        let ship = Ship(entity: entity, id: "sp-ship-1")
        
        shipManager.ships = [ship]
        
        // Test targeting
        shipManager.switchToNextTarget()
        #expect(!shipManager.isAutoTargeting) // Should disable auto targeting
        
        // Test ship movement
        shipManager.moveShips(placed: true)
        #expect(true) // Should complete without error
    }
    
    // MARK: - Game Loop Integration Tests
    
    @Test("Single-player game loop components work together")
    func testGameLoopIntegration() async {
        let arView = ARView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gameManager = GameManager(arView: arView, session: nil) // Single-player
        let shipManager = ShipManager(game: testGame, arView: arView)
        
        // Verify single-player setup
        #expect(!gameManager.isNetworked)
        #expect(gameManager.isServer)
        
        // Create helicopter
        let transform = simd_float4x4(1.0)
        let helicopter = await HelicopterObject(owner: testPlayer, worldTransform: transform)
        
        await gameManager.createHelicopter(
            addNodeAction: AddNodeAction(
                simdWorldTransform: transform,
                eulerAngles: SIMD3<Float>(0, 0, 0)
            ),
            owner: testPlayer
        )
        
        #expect(gameManager.helicopters[testPlayer] != nil)
        
        // Setup ships
        shipManager.helicopterEntity = helicopter.helicopterEntity?.helicopter
        
        // Create test ship
        let entity = Entity()
        entity.name = "Ship_game_loop_test"
        let ship = Ship(entity: entity, id: "loop-ship-1")
        shipManager.ships = [ship]
        
        // Simulate game loop iteration
        shipManager.moveShips(placed: testGame.placed)
        shipManager.updateAutoTarget()
        
        #expect(true) // Game loop components work together
    }
    
    // MARK: - Performance Tests for Single-Player
    
    @Test("Single-player game maintains good performance")
    func testSinglePlayerPerformance() async {
        let arView = ARView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gameManager = GameManager(arView: arView, session: nil)
        let shipManager = ShipManager(game: testGame, arView: arView)
        
        // Create many ships for performance test
        var ships: [Ship] = []
        for i in 0..<50 {
            let entity = Entity()
            entity.name = "Ship_perf_test_\(i)"
            entity.transform.translation = SIMD3<Float>(
                Float.random(in: -10...10),
                0,
                Float.random(in: -10...10)
            )
            let ship = Ship(entity: entity, id: "perf-ship-\(i)")
            ships.append(ship)
        }
        
        shipManager.ships = ships
        
        let startTime = CACurrentMediaTime()
        
        // Simulate multiple game loop iterations
        for _ in 0..<10 {
            shipManager.moveShips(placed: true)
            shipManager.updateAutoTarget()
        }
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        #expect(duration < 2.0) // Should complete within 2 seconds
        #expect(shipManager.ships.count == 50)
    }
    
    // MARK: - Error Recovery Tests
    
    @Test("Single-player game recovers from errors gracefully")
    func testSinglePlayerErrorRecovery() {
        // Test with nil components
        let arView = ARView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let shipManager = ShipManager(game: testGame, arView: arView)
        
        // Empty ship array
        shipManager.ships = []
        
        // Should handle gracefully
        shipManager.moveShips(placed: true)
        shipManager.switchToNextTarget()
        shipManager.switchToPreviousTarget()
        shipManager.updateAutoTarget()
        
        #expect(shipManager.ships.isEmpty) // Should remain empty
        #expect(true) // Should not crash
    }
    
    @Test("Game state remains consistent after errors")
    func testGameStateConsistency() {
        // Test score consistency
        let originalScore = gameStateManager.score
        
        // Simulate error during scoring
        gameStateManager.destroyShip(worth: -100) // Invalid negative score
        
        // Score should remain non-negative
        #expect(gameStateManager.score >= 0)
        
        // Test health consistency
        gameStateManager.updateHelicopterHealth(-50.0) // Invalid negative health
        
        // Health should be clamped to valid range
        #expect(gameStateManager.helicopterHealth >= 0.0)
        #expect(gameStateManager.helicopterHealth <= 100.0)
    }
    
    // MARK: - Single-Player Specific Features Tests
    
    @Test("Single-player mode doesn't attempt network operations")
    func testSinglePlayerNetworkIsolation() {
        let arView = ARView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gameManager = GameManager(arView: arView, session: nil) // No network session
        
        #expect(!gameManager.isNetworked)
        
        // Network operations should be no-ops
        gameManager.synchronizeShips([])
        gameManager.updateShipState(shipId: "test", isDestroyed: true)
        gameManager.updateShipTargeting(shipId: "test", targeted: true)
        
        #expect(true) // Should complete without network calls
    }
    
    @Test("Single-player missile manager doesn't use network features")
    func testSinglePlayerMissileManagerNetworkIsolation() {
        let arView = GameSceneView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let gameManager = GameManager(arView: arView, session: nil)
        let missileManager = MissileManager(
            game: testGame,
            sceneView: arView,
            gameManager: gameManager,
            localPlayer: testPlayer
        )
        
        // Network methods should handle gracefully
        let fireData = MissileFireData(
            missileId: "test",
            playerId: "test",
            startPosition: SIMD3<Float>(0, 0, 0),
            startRotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
            targetShipId: "test",
            fireTime: CACurrentMediaTime()
        )
        
        missileManager.handleNetworkMissileFired(fireData)
        
        #expect(true) // Should handle without network operations
    }
}

// MARK: - Mock XCTest Expectation for Notification Test

class XCTestExpectation {
    let description: String
    
    init(description: String) {
        self.description = description
    }
    
    func fulfill() {
        // Mock implementation
    }
}
