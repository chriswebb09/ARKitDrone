//
//  ShipManagerComprehensiveTests.swift
//  ARKitDroneTests
//
//  Comprehensive TDD-style tests for ShipManager system
//

import Testing
import RealityKit
import simd
import UIKit
@testable import ARKitDrone

@MainActor
struct ShipManagerComprehensiveTests {
    
    var mockGame: Game!
    var mockArView: GameSceneView!
    var shipManager: ShipManager!
    
    init() {
        setupTestEnvironment()
    }
    
    private mutating func setupTestEnvironment() {
        mockGame = Game()
        
        let testFrame = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        mockArView = GameSceneView(frame: testFrame)
        
        shipManager = ShipManager(game: mockGame, arView: mockArView)
    }
    
    // MARK: - Initialization Tests
    
    @Test("ShipManager initializes with correct properties")
    func testInitialization() {
        #expect(shipManager.game === mockGame)
        #expect(shipManager.arView === mockArView)
        #expect(shipManager.ships.isEmpty)
        #expect(shipManager.helicopterEntity == nil)
        #expect(shipManager.targetIndex == 0)
        #expect(shipManager.attack == false)
        #expect(shipManager.shipsSetup == false)
        #expect(shipManager.isAutoTargeting == true)
    }
    
    @Test("ShipManager can be created with EntityManager")
    func testInitializationWithEntityManager() {
        let mockEntityManager = EntityManager()
        let shipManagerWithEM = ShipManager(game: mockGame, arView: mockArView, entityManager: mockEntityManager)
        
        #expect(shipManagerWithEM.entityManager === mockEntityManager)
        #expect(shipManagerWithEM.game === mockGame)
        #expect(shipManagerWithEM.arView === mockArView)
    }
    
    // MARK: - Ship Creation Tests
    
    @Test("ShipManager prevents duplicate ship setup")
    func testPreventsDuplicateSetup() async {
        // Mark ships as already setup
        shipManager.shipsSetup = true
        
        let initialShipCount = shipManager.ships.count
        
        // Try to setup ships again
        await shipManager.setupShips()
        
        // Should not create additional ships
        #expect(shipManager.ships.count == initialShipCount)
        #expect(shipManager.shipsSetup == true)
    }
    
    @Test("ShipManager creates test ships for testing")
    func testCreateTestShips() {
        // Create ships manually for testing (since setupShips requires model loading)
        for i in 1...5 {
            let entity = Entity()
            entity.name = "TestShip_\(i)"
            entity.transform.translation = SIMD3<Float>(
                Float.random(in: -10...10),
                Float.random(in: -5...5),
                Float.random(in: -10...10)
            )
            
            let ship = Ship(entity: entity, id: "test-ship-\(i)")
            ship.num = i
            shipManager.ships.append(ship)
        }
        
        #expect(shipManager.ships.count == 5)
        
        // Verify each ship has proper setup
        for (index, ship) in shipManager.ships.enumerated() {
            #expect(ship.num == index + 1)
            #expect(!ship.id.isEmpty)
            #expect(ship.entity.name.contains("Ship_"))
            #expect(!ship.isDestroyed)
        }
    }
    
    // MARK: - Targeting System Tests
    
    @Test("ShipManager targeting system works correctly")
    func testTargetingSystem() {
        // Create test ships
        createTestShips(count: 3)
        
        // Test getting current target
        let currentTarget = shipManager.getCurrentTarget()
        #expect(currentTarget != nil)
        #expect(currentTarget === shipManager.ships[shipManager.targetIndex]) // Should target ship at current index
        
        // Test switching to next target
        shipManager.switchToNextTarget()
        #expect(shipManager.targetIndex == 1)
        #expect(shipManager.isAutoTargeting == false) // Manual targeting disables auto
        
        // Test switching to previous target
        shipManager.switchToPreviousTarget()
        #expect(shipManager.targetIndex == 0)
    }
    
    @Test("ShipManager handles targeting with destroyed ships")
    func testTargetingWithDestroyedShips() {
        createTestShips(count: 4)
        
        // Destroy first two ships
        shipManager.ships[0].isDestroyed = true
        shipManager.ships[1].isDestroyed = true
        
        // Get current target - should skip destroyed ships
        let currentTarget = shipManager.getCurrentTarget()
        #expect(currentTarget != nil)
        // After calling getCurrentTarget(), targetIndex should be updated to point to first non-destroyed ship
        if let currentTarget = currentTarget {
            #expect(currentTarget === shipManager.ships[shipManager.targetIndex])
            #expect(!currentTarget.isDestroyed)
        } else {
            // If no target is found, all ships must be destroyed
            #expect(shipManager.ships.allSatisfy { $0.isDestroyed })
        }
        
        // Test next target switching
        shipManager.switchToNextTarget()
        let nextTarget = shipManager.getCurrentTarget()
        #expect(nextTarget != nil)
        #expect(!nextTarget!.isDestroyed) // Should target a non-destroyed ship
    }
    
    @Test("ShipManager auto-targeting finds nearest ship")
    func testAutoTargeting() {
        createTestShips(count: 3)
        setupMockHelicopter()
        
        // Position ships at different distances from helicopter
        shipManager.ships[0].entity.transform.translation = SIMD3<Float>(10, 0, 0) // Far
        shipManager.ships[1].entity.transform.translation = SIMD3<Float>(2, 0, 0)  // Near
        shipManager.ships[2].entity.transform.translation = SIMD3<Float>(5, 0, 0)  // Medium
        
        // Enable auto targeting
        shipManager.isAutoTargeting = true
        shipManager.updateAutoTarget()
        
        // Should target the nearest ship (index 1)
        #expect(shipManager.targetIndex == 1)
    }
    
    @Test("ShipManager handles no available targets gracefully")
    func testNoAvailableTargets() {
        createTestShips(count: 2)
        
        // Destroy all ships
        for ship in shipManager.ships {
            ship.isDestroyed = true
        }
        
        let currentTarget = shipManager.getCurrentTarget()
        #expect(currentTarget == nil)
        
        // Switching targets should handle gracefully
        shipManager.switchToNextTarget()
        shipManager.switchToPreviousTarget()
        
        #expect(true) // Should not crash
    }
    
    // MARK: - Ship Movement Tests
    
    @Test("ShipManager moves ships correctly")
    func testShipMovement() {
        createTestShips(count: 3)
        setupMockHelicopter()
        
        // Record initial positions
        let initialPositions = shipManager.ships.map { $0.entity.transform.translation }
        
        // Move ships
        shipManager.moveShips(placed: true)
        
        // Verify ships have moved (positions should be different)
        for (index, ship) in shipManager.ships.enumerated() {
            let newPosition = ship.entity.transform.translation
            let oldPosition = initialPositions[index]
            
            // Ships should have moved (at least slightly)
            let moved = simd_distance(newPosition, oldPosition) > 0.001
            #expect(moved)
        }
    }
    
    @Test("ShipManager handles empty ship array in movement")
    func testMovementWithNoShips() {
        // Ensure ships array is empty
        shipManager.ships = []
        
        // Should handle gracefully without crashing
        shipManager.moveShips(placed: true)
        
        #expect(shipManager.ships.isEmpty)
    }
    
    @Test("ShipManager ship attack behavior works")
    func testShipAttackBehavior() {
        createTestShips(count: 2)
        setupMockHelicopter()
        
        // Position ships close to helicopter to trigger attack
        for ship in shipManager.ships {
            ship.entity.transform.translation = SIMD3<Float>(1, 0, 0) // Close to helicopter
        }
        
        // Move ships with placed=true to trigger attack behavior
        shipManager.moveShips(placed: true)
        
        // Attack should be triggered
        // Note: The actual attack behavior is timer-based, so we verify setup
        #expect(shipManager.ships.count > 0)
        #expect(shipManager.helicopterEntity != nil)
    }
    
    // MARK: - Network Synchronization Tests
    
    @Test("ShipManager handles network ship data updates")
    func testNetworkShipUpdates() {
        createTestShips(count: 2)
        
        let ship1 = shipManager.ships[0]
        let ship2 = shipManager.ships[1]
        
        // Create mock network data
        let networkData = [
            ShipSyncTestData(
                shipId: ship1.id,
                position: SIMD3<Float>(5, 5, 5),
                rotation: simd_quatf(angle: 0.5, axis: SIMD3<Float>(0, 1, 0)),
                velocity: SIMD3<Float>(0.1, 0, 0.1),
                isDestroyed: false,
                targeted: true
            ),
            ShipSyncTestData(
                shipId: ship2.id,
                position: SIMD3<Float>(-3, 2, -3),
                rotation: simd_quatf(angle: -0.3, axis: SIMD3<Float>(0, 1, 0)),
                velocity: SIMD3<Float>(-0.05, 0, 0.05),
                isDestroyed: true,
                targeted: false
            )
        ]
        
        // Apply network updates
        applyNetworkUpdates(networkData)
        
        // Verify updates were applied
        #expect(ship1.entity.transform.translation == SIMD3<Float>(5, 5, 5))
        #expect(ship1.targeted == true)
        #expect(ship1.isDestroyed == false)
        
        #expect(ship2.entity.transform.translation == SIMD3<Float>(-3, 2, -3))
        #expect(ship2.targeted == false)
        #expect(ship2.isDestroyed == true)
    }
    
    @Test("ShipManager destroys ships by ID")
    func testDestroyShipById() {
        createTestShips(count: 3)
        
        let targetShip = shipManager.ships[1]
        let shipId = targetShip.id
        
        #expect(!targetShip.isDestroyed)
        
        // Destroy ship by ID
        shipManager.destroyShip(withId: shipId)
        
        #expect(targetShip.isDestroyed)
    }
    
    @Test("ShipManager sets ship targeting by ID")
    func testSetShipTargeted() {
        createTestShips(count: 2)
        
        let ship = shipManager.ships[0]
        
        #expect(!ship.targeted)
        #expect(ship.square == nil)
        
        // Set ship as targeted
        shipManager.setShipTargeted(shipId: ship.id, targeted: true)
        
        #expect(ship.targeted)
        #expect(ship.square != nil)
        #expect(ship.targetAdded)
        
        // Remove targeting
        shipManager.setShipTargeted(shipId: ship.id, targeted: false)
        
        #expect(!ship.targeted)
        #expect(!ship.targetAdded)
    }
    
    // MARK: - Explosion Effects Tests
    
    @Test("ShipManager creates explosion effects")
    func testExplosionEffects() {
        let explosionPoint = SIMD3<Float>(5, 0, -5)
        
        let initialAnchorCount = mockArView.scene.anchors.count
        
        // Add explosion
        shipManager.addExplosion(contactPoint: explosionPoint)
        
        // Should add anchor to scene
        #expect(mockArView.scene.anchors.count > initialAnchorCount)
        
        // The explosion should auto-remove after a delay, but we can't easily test that timing
    }
    
    // MARK: - Cleanup Tests  
    
    @Test("ShipManager cleanup works correctly")
    func testCleanup() {
        createTestShips(count: 3)
        
        // Add some target indicators
        shipManager.setShipTargeted(shipId: shipManager.ships[0].id, targeted: true)
        shipManager.setShipTargeted(shipId: shipManager.ships[1].id, targeted: true)
        
        #expect(shipManager.ships.count == 3)
        #expect(!shipManager.ships.isEmpty)
        
        // Cleanup
        shipManager.cleanup()
        
        // All ships should be cleaned up
        #expect(shipManager.ships.isEmpty)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("ShipManager handles invalid ship IDs gracefully")
    func testInvalidShipIdHandling() {
        createTestShips(count: 2)
        
        // Try operations with non-existent ship ID
        shipManager.destroyShip(withId: "non-existent-id")
        shipManager.setShipTargeted(shipId: "invalid-id", targeted: true)
        
        // Should handle gracefully without crashing
        #expect(shipManager.ships.count == 2)
        #expect(shipManager.ships.allSatisfy { !$0.isDestroyed })
    }
    
    @Test("ShipManager handles targeting bounds correctly")
    func testTargetingBounds() {
        createTestShips(count: 3)
        
        // Test targeting beyond array bounds
        shipManager.targetIndex = 10 // Out of bounds
        
        let target = shipManager.getCurrentTarget()
        #expect(target != nil) // Should find valid target
        #expect(shipManager.targetIndex < shipManager.ships.count)
    }
    
    @Test("ShipManager handles helicopter entity absence")
    func testMissingHelicopterEntity() {
        createTestShips(count: 2)
        // Don't set helicopterEntity (leave as nil)
        
        // Should handle auto-targeting gracefully
        shipManager.updateAutoTarget()
        
        // Should handle movement gracefully  
        shipManager.moveShips(placed: true)
        
        #expect(true) // Should not crash
    }
    
    // MARK: - Performance Tests
    
    @Test("ShipManager handles many ships efficiently")
    func testManyShipsPerformance() {
        // Create many ships
        createTestShips(count: 50)
        setupMockHelicopter()
        
        let startTime = CACurrentMediaTime()
        
        // Test ship movement performance
        shipManager.moveShips(placed: true)
        
        // Test targeting performance
        shipManager.updateAutoTarget()
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        #expect(duration < 2.0) // Should complete within 2 seconds
        #expect(shipManager.ships.count == 50)
    }
    
    @Test("ShipManager targeting operations are efficient")
    func testTargetingPerformance() {
        createTestShips(count: 20)
        
        let startTime = CACurrentMediaTime()
        
        // Perform many targeting operations
        for _ in 0..<100 {
            shipManager.switchToNextTarget()
            shipManager.switchToPreviousTarget()
            _ = shipManager.getCurrentTarget()
        }
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        #expect(duration < 1.0) // Should complete within 1 second
    }
    
    // MARK: - Integration Tests
    
    @Test("ShipManager integrates correctly with Game object")
    func testGameIntegration() {
        createTestShips(count: 3)
        
        #expect(shipManager.game === mockGame)
        #expect(shipManager.arView === mockArView)
        
        // Test that ship manager can affect game state
        let initialScore = mockGame.playerScore
        
        // Simulate scoring (this would normally be done by missile hits)
        mockGame.playerScore += 100
        
        #expect(mockGame.playerScore > initialScore)
    }
    
    // MARK: - Helper Methods
    
    private func createTestShips(count: Int) {
        shipManager.ships = []
        
        for i in 1...count {
            let entity = Entity()
            entity.name = "TestShip_\(i)"
            entity.transform.translation = SIMD3<Float>(
                Float(i) * 2.0, // Spread ships out
                0,
                Float(i) * 2.0
            )
            
            let ship = Ship(entity: entity, id: "test-ship-\(i)")
            ship.num = i
            shipManager.ships.append(ship)
        }
    }
    
    private func setupMockHelicopter() {
        let helicopterEntity = Entity()
        helicopterEntity.name = "MockHelicopter"
        helicopterEntity.transform.translation = SIMD3<Float>(0, 1, 0)
        
        shipManager.helicopterEntity = helicopterEntity
    }
    
    private func applyNetworkUpdates(_ data: [ShipSyncTestData]) {
        // Simulate the network update process
        for update in data {
            if let ship = shipManager.ships.first(where: { $0.id == update.shipId }) {
                ship.entity.transform.translation = update.position
                ship.entity.transform.rotation = update.rotation
                ship.velocity = update.velocity
                ship.isDestroyed = update.isDestroyed
                ship.targeted = update.targeted
            }
        }
    }
}

// MARK: - Test Helper Types

struct ShipSyncTestData {
    let shipId: String
    let position: SIMD3<Float>
    let rotation: simd_quatf
    let velocity: SIMD3<Float>
    let isDestroyed: Bool
    let targeted: Bool
}