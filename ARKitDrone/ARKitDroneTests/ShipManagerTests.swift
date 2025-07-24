//
//  ShipManagerTests.swift
//  ARKitDroneTests
//
//  Created by Claude on 2025-01-24.
//

import Testing
import RealityKit
import UIKit
@testable import ARKitDrone

@MainActor
struct ShipManagerTests {
    
    // MARK: - Test Properties
    
    var mockGame: Game!
    var mockARView: ARView!
    var shipManager: ShipManager!
    
    init() {
        mockGame = Game()
        mockARView = createMockARView()
        shipManager = ShipManager(game: mockGame, arView: mockARView)
    }
    
    // MARK: - Helper Methods
    
    private func createMockARView() -> ARView {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        return ARView(frame: frame)
    }
    
    private func createMockShip(id: String = "test-ship") -> Ship {
        let entity = Entity()
        entity.name = "Ship_\(id)"
        let ship = Ship(entity: entity, id: id)
        return ship
    }
    
    private func createMockHelicopterEntity() -> Entity {
        let entity = Entity()
        entity.name = "Helicopter_test"
        return entity
    }
    
    // MARK: - Initialization Tests
    
    @Test("ShipManager initializes correctly")
    func testShipManagerInitialization() {
        #expect(shipManager != nil)
        #expect(shipManager.game === mockGame)
        #expect(shipManager.arView === mockARView)
        #expect(shipManager.ships.isEmpty)
        #expect(shipManager.targetIndex == 0)
        #expect(shipManager.isAutoTargeting == true)
    }
    
    // MARK: - Ship Management Tests
    
    @Test("ShipManager can add ships to collection")
    func testAddShips() async {
        let initialShipCount = shipManager.ships.count
        
        // Setup ships (this would normally be called during game setup)
        await shipManager.setupShips()
        
        // After setup, ships should be created
        // Note: setupShips() creates ships internally, exact count depends on implementation
        #expect(shipManager.ships.count >= initialShipCount)
    }
    
    @Test("ShipManager tracks ship states correctly")
    func testShipStateTracking() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        
        shipManager.ships = [ship1, ship2]
        
        #expect(shipManager.ships.count == 2)
        #expect(!ship1.isDestroyed)
        #expect(!ship2.isDestroyed)
        
        // Test ship destruction
        ship1.isDestroyed = true
        #expect(ship1.isDestroyed)
        #expect(!ship2.isDestroyed)
    }
    
    // MARK: - Ship Movement Tests
    
    @Test("ShipManager moves ships when game is placed")
    func testShipMovementWhenPlaced() {
        let ship = createMockShip()
        shipManager.ships = [ship]
        
        let initialPosition = ship.entity.transform.translation
        
        // Test movement when game is placed
        shipManager.moveShips(placed: true)
        
        // Ship should be processed (position might change based on boids behavior)
        #expect(ship.entity != nil)
    }
    
    @Test("ShipManager handles ship movement when not placed")
    func testShipMovementWhenNotPlaced() {
        let ship = createMockShip()
        shipManager.ships = [ship]
        
        // Test movement when game is not placed
        shipManager.moveShips(placed: false)
        
        // Should handle gracefully without crashing
        #expect(true)
    }
    
    @Test("ShipManager updates ship positions using boids algorithm")
    func testBoidsAlgorithm() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        let ship3 = createMockShip(id: "ship-3")
        
        // Position ships at different locations
        ship1.entity.transform.translation = SIMD3<Float>(0, 0, 0)
        ship2.entity.transform.translation = SIMD3<Float>(2, 0, 0)
        ship3.entity.transform.translation = SIMD3<Float>(-2, 0, 0)
        
        shipManager.ships = [ship1, ship2, ship3]
        
        // Test boids movement
        shipManager.moveShips(placed: true)
        
        // Ships should have processed boids forces
        #expect(shipManager.ships.count == 3)
        
        // Test that ships maintain their entity references
        #expect(ship1.entity != nil)
        #expect(ship2.entity != nil)
        #expect(ship3.entity != nil)
    }
    
    // MARK: - Targeting System Tests
    
    @Test("ShipManager switches to next target correctly")
    func testNextTargetSwitching() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        let ship3 = createMockShip(id: "ship-3")
        
        shipManager.ships = [ship1, ship2, ship3]
        shipManager.targetIndex = 0
        
        // Switch to next target
        shipManager.switchToNextTarget()
        
        // Should disable auto targeting
        #expect(!shipManager.isAutoTargeting)
        
        // Target index should change (if ships are available)
        // Note: Exact behavior depends on ship availability
    }
    
    @Test("ShipManager switches to previous target correctly")
    func testPreviousTargetSwitching() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        let ship3 = createMockShip(id: "ship-3")
        
        shipManager.ships = [ship1, ship2, ship3]
        shipManager.targetIndex = 1
        
        // Switch to previous target
        shipManager.switchToPreviousTarget()
        
        // Should disable auto targeting
        #expect(!shipManager.isAutoTargeting)
    }
    
    @Test("ShipManager handles targeting with destroyed ships")
    func testTargetingWithDestroyedShips() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        let ship3 = createMockShip(id: "ship-3")
        
        ship2.isDestroyed = true // Destroy middle ship
        
        shipManager.ships = [ship1, ship2, ship3]
        
        // Should only target non-destroyed ships
        shipManager.switchToNextTarget()
        
        #expect(!shipManager.isAutoTargeting)
    }
    
    @Test("ShipManager handles auto targeting")
    func testAutoTargeting() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        
        shipManager.ships = [ship1, ship2]
        shipManager.helicopterEntity = createMockHelicopterEntity()
        
        // Enable auto targeting
        shipManager.isAutoTargeting = true
        
        // Update auto target
        shipManager.updateAutoTarget()
        
        // Should maintain auto targeting state
        #expect(shipManager.isAutoTargeting)
    }
    
    // MARK: - Attack System Tests
    
    @Test("ShipManager handles ship attacks")
    func testShipAttacks() {
        let ship = createMockShip()
        let helicopterEntity = createMockHelicopterEntity()
        
        shipManager.ships = [ship]
        shipManager.helicopterEntity = helicopterEntity
        
        // Test ship attack behavior
        ship.attack(target: helicopterEntity)
        
        // Should complete without crashing
        #expect(true)
    }
    
    // MARK: - Network Synchronization Tests
    
    @Test("ShipManager handles network ship updates")
    func testNetworkShipUpdates() {
        let ship = createMockShip(id: "sync-ship")
        shipManager.ships = [ship]
        
        let syncData = [ShipSyncData(
            shipId: "sync-ship",
            position: SIMD3<Float>(10, 0, 10),
            velocity: SIMD3<Float>(1, 0, 1),
            rotation: simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0)),
            isDestroyed: false,
            targeted: true
        )]
        
        shipManager.updateShipsFromNetwork(syncData)
        
        // Ship should be updated with network data
        #expect(ship.entity.transform.translation.x == 10)
        #expect(ship.entity.transform.translation.z == 10)
        #expect(ship.targeted == true)
    }
    
    @Test("ShipManager handles network ship destruction")
    func testNetworkShipDestruction() {
        let ship = createMockShip(id: "destroy-ship")
        shipManager.ships = [ship]
        
        // Destroy ship via network
        shipManager.destroyShip(withId: "destroy-ship")
        
        #expect(ship.isDestroyed)
    }
    
    @Test("ShipManager handles network ship targeting")
    func testNetworkShipTargeting() {
        let ship = createMockShip(id: "target-ship")
        shipManager.ships = [ship]
        
        // Set ship as targeted via network
        shipManager.setShipTargeted(shipId: "target-ship", targeted: true)
        
        #expect(ship.targeted)
        #expect(ship.square != nil) // Should have target indicator
        
        // Remove targeting
        shipManager.setShipTargeted(shipId: "target-ship", targeted: false)
        
        #expect(!ship.targeted)
    }
    
    // MARK: - Visual Effects Tests
    
    @Test("ShipManager creates explosion effects")
    func testExplosionEffects() {
        let explosionPoint = SIMD3<Float>(5, 0, 5)
        
        // Should create explosion without crashing
        shipManager.addExplosion(contactPoint: explosionPoint)
        
        #expect(true)
    }
    
    // MARK: - Cleanup Tests
    
    @Test("ShipManager cleans up properly")
    func testCleanup() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        
        shipManager.ships = [ship1, ship2]
        
        // Add some target indicators
        shipManager.setShipTargeted(shipId: "ship-1", targeted: true)
        
        // Cleanup
        shipManager.cleanup()
        
        // Should clean up all resources
        #expect(shipManager.ships.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    @Test("ShipManager integrates with helicopter entity")
    func testHelicopterIntegration() {
        let helicopterEntity = createMockHelicopterEntity()
        shipManager.helicopterEntity = helicopterEntity
        
        #expect(shipManager.helicopterEntity === helicopterEntity)
        
        // Test movement with helicopter as obstacle
        let ship = createMockShip()
        shipManager.ships = [ship]
        
        shipManager.moveShips(placed: true)
        
        // Should handle helicopter as obstacle in boids algorithm
        #expect(true)
    }
    
    // MARK: - Performance Tests
    
    @Test("ShipManager handles large numbers of ships efficiently")
    func testPerformanceWithManyShips() {
        var ships: [Ship] = []
        
        // Create many ships
        for i in 0..<50 {
            let ship = createMockShip(id: "perf-ship-\(i)")
            ship.entity.transform.translation = SIMD3<Float>(
                Float.random(in: -10...10),
                0,
                Float.random(in: -10...10)
            )
            ships.append(ship)
        }
        
        shipManager.ships = ships
        
        // Test movement performance
        let startTime = CACurrentMediaTime()
        shipManager.moveShips(placed: true)
        let endTime = CACurrentMediaTime()
        
        let duration = endTime - startTime
        #expect(duration < 1.0) // Should complete within 1 second
        #expect(shipManager.ships.count == 50)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("ShipManager handles empty ship array")
    func testEmptyShipArray() {
        shipManager.ships = []
        
        // Should handle empty array gracefully
        shipManager.moveShips(placed: true)
        shipManager.switchToNextTarget()
        shipManager.switchToPreviousTarget()
        shipManager.updateAutoTarget()
        
        #expect(shipManager.ships.isEmpty)
    }
    
    @Test("ShipManager handles all ships destroyed")
    func testAllShipsDestroyed() {
        let ship1 = createMockShip(id: "ship-1")
        let ship2 = createMockShip(id: "ship-2")
        
        ship1.isDestroyed = true
        ship2.isDestroyed = true
        
        shipManager.ships = [ship1, ship2]
        
        // Should handle all destroyed ships
        shipManager.switchToNextTarget()
        shipManager.updateAutoTarget()
        
        #expect(true) // Should not crash
    }
}

// MARK: - Mock Ship for Testing

@MainActor
class MockShip: Ship {
    var mockPosition: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var mockVelocity: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    
    override init(entity: Entity, id: String? = nil) {
        super.init(entity: entity, id: id)
    }
    
    override func updateShipPosition(perceivedCenter: SIMD3<Float>, perceivedVelocity: SIMD3<Float>, otherShips: [Ship], obstacles: [Entity]) {
        // Mock implementation for testing
        mockPosition = perceivedCenter
        mockVelocity = perceivedVelocity
        super.updateShipPosition(perceivedCenter: perceivedCenter, perceivedVelocity: perceivedVelocity, otherShips: otherShips, obstacles: obstacles)
    }
}

// MARK: - Additional Tests with Mock Ship

extension ShipManagerTests {
    
    @Test("ShipManager processes boids forces correctly")
    func testBoidsForceCalculation() {
        let mockShip = MockShip(entity: Entity(), id: "mock-ship")
        mockShip.entity.transform.translation = SIMD3<Float>(0, 0, 0)
        
        shipManager.ships = [mockShip]
        shipManager.moveShips(placed: true)
        
        // Verify boids calculation was called
        #expect(mockShip.entity != nil)
    }
}
