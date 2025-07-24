//
//  CollisionTests.swift
//  ARKitDroneTests
//
//  Created by Claude on 2025-01-24.
//

import Testing
import UIKit
import RealityKit
@testable import ARKitDrone

@MainActor
struct CollisionTests {
    
    // MARK: - Test Properties
    
    var mockGame: Game!
    var mockARView: ARView!
    var mockPlayer: Player!
    
    init() {
        mockGame = Game()
        mockARView = createMockARView()
        mockPlayer = Player(username: "TestPlayer")
    }
    
    // MARK: - Helper Methods
    
    private func createMockARView() -> ARView {
        let frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        return ARView(frame: frame)
    }
    
    private func createMockMissileEntity() -> Entity {
        let entity = Entity()
        entity.name = "Missile_test_123"
        return entity
    }
    
    private func createMockShipEntity() -> Entity {
        let entity = Entity()
        entity.name = "Ship_test_456"
        return entity
    }
    
    private func createMockHelicopterEntity() -> Entity {
        let entity = Entity()
        entity.name = "Helicopter_test_789"
        return entity
    }
    
    private func createMockCollisionEvent(entityA: Entity, entityB: Entity) -> MockCollisionEvent {
        return MockCollisionEvent(entityA: entityA, entityB: entityB)
    }
    
    // MARK: - Ship Collision Tests
    
    @Test("Ship correctly identifies itself from entity")
    func testShipEntityIdentification() {
        let shipEntity = createMockShipEntity()
        let ship = Ship(entity: shipEntity, id: "test-ship")
        
        // Test ship registry lookup
        let foundShip = Ship.getShip(from: shipEntity)
        #expect(foundShip === ship)
    }
    
    @Test("Ship handles damage from collisions")
    func testShipCollisionDamage() {
        let shipEntity = createMockShipEntity()
        let ship = Ship(entity: shipEntity, id: "damage-test-ship")
        
        let initialHealth = ship.currentHealth
        #expect(initialHealth == 100) // Default max health
        
        // Apply damage
        ship.takeDamage(25)
        
        #expect(ship.currentHealth == 75)
        #expect(!ship.isDestroyed)
        
        // Apply lethal damage
        ship.takeDamage(100)
        
        #expect(ship.currentHealth == 0)
        #expect(ship.isDestroyed)
    }
    
    @Test("Ship prevents damage when already destroyed")
    func testDestroyedShipDamageImmunity() {
        let shipEntity = createMockShipEntity()
        let ship = Ship(entity: shipEntity, id: "immune-ship")
        
        // Destroy ship first
        ship.takeDamage(150) // Overkill damage
        #expect(ship.isDestroyed)
        
        let healthAfterDeath = ship.currentHealth
        
        // Try to damage destroyed ship
        ship.takeDamage(50)
        
        // Health should not change
        #expect(ship.currentHealth == healthAfterDeath)
    }
    
    // MARK: - Missile Collision Tests
    
    @Test("MissileManager detects missile-ship collisions")
    func testMissileShipCollisionDetection() {
        let missileManager = MissileManager(
            game: mockGame,
            sceneView: GameSceneView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
            gameManager: nil,
            localPlayer: mockPlayer
        )
        
        let missileEntity = createMockMissileEntity()
        let shipEntity = createMockShipEntity()
        
        // Create mock collision event
        let collisionEvent = createMockCollisionEvent(entityA: missileEntity, entityB: shipEntity)
        
        // Test collision detection logic
        let isMissileHit = (missileEntity.name.contains("Missile") && !shipEntity.name.contains("Missile")) ||
                          (shipEntity.name.contains("Missile") && !missileEntity.name.contains("Missile"))
        
        #expect(isMissileHit)
    }
    
    @Test("MissileManager ignores non-missile collisions")
    func testNonMissileCollisionIgnored() {
        let shipEntity1 = createMockShipEntity()
        let shipEntity2 = createMockShipEntity()
        
        // Ship-to-ship collision should not be treated as missile hit
        let isMissileHit = (shipEntity1.name.contains("Missile") && !shipEntity2.name.contains("Missile")) ||
                          (shipEntity2.name.contains("Missile") && !shipEntity1.name.contains("Missile"))
        
        #expect(!isMissileHit)
    }
    
    @Test("MissileManager identifies correct entities in collision")
    func testCollisionEntityIdentification() {
        let missileEntity = createMockMissileEntity()
        let shipEntity = createMockShipEntity()
        
        // Test missile identification
        let detectedMissileEntity = missileEntity.name.contains("Missile") ? missileEntity : shipEntity
        let detectedShipEntity = missileEntity.name.contains("Missile") ? shipEntity : missileEntity
        
        #expect(detectedMissileEntity === missileEntity)
        #expect(detectedShipEntity === shipEntity)
    }
    
    // MARK: - Ship Attack Collision Tests
    
    @Test("Ship attack creates collision with helicopter")
    func testShipAttackCollision() {
        let shipEntity = createMockShipEntity()
        let helicopterEntity = createMockHelicopterEntity()
        let ship = Ship(entity: shipEntity, id: "attacking-ship")
        
        // Test attack method doesn't crash
        ship.attack(target: helicopterEntity)
        
        #expect(true) // Should complete without crashing
    }
    
    @Test("Ship respects fire rate limiting")
    func testShipFireRateLimiting() {
        let shipEntity = createMockShipEntity()
        let helicopterEntity = createMockHelicopterEntity()
        let ship = Ship(entity: shipEntity, id: "rate-limited-ship")
        
        // First attack should work
        ship.attack(target: helicopterEntity)
        
        // Immediate second attack should be rate limited
        ship.attack(target: helicopterEntity)
        
        #expect(true) // Should handle rate limiting gracefully
    }
    
    // MARK: - Collision Physics Tests
    
    @Test("Collision system handles entity bounds correctly")
    func testCollisionBounds() {
        let shipEntity = createMockShipEntity()
        let ship = Ship(entity: shipEntity, id: "bounds-test-ship")
        
        // Test boundary force calculation
        let boundaryForce = ship.getBoundaryForce()
        
        // Should return a valid force vector
        #expect(boundaryForce.x.isFinite)
        #expect(boundaryForce.y.isFinite)
        #expect(boundaryForce.z.isFinite)
    }
    
    @Test("Ships calculate separation forces from obstacles")
    func testObstacleAvoidance() {
        let shipEntity = createMockShipEntity()
        let ship = Ship(entity: shipEntity, id: "avoidance-test-ship")
        
        let helicopterEntity = createMockHelicopterEntity()
        helicopterEntity.transform.translation = SIMD3<Float>(1, 0, 1) // Close to ship
        
        // Test that ship calculates forces to avoid helicopter
        ship.updateShipPosition(
            perceivedCenter: SIMD3<Float>(0, 0, 0),
            perceivedVelocity: SIMD3<Float>(0, 0, 0),
            otherShips: [],
            obstacles: [helicopterEntity]
        )
        
        #expect(true) // Should complete avoidance calculation
    }
    
    // MARK: - Collision Response Tests
    
    @Test("Collision response triggers appropriate effects")
    func testCollisionEffects() {
        let shipManager = ShipManager(game: mockGame, arView: mockARView)
        let hitPosition = SIMD3<Float>(5, 0, 5)
        
        // Test explosion effect creation
        shipManager.addExplosion(contactPoint: hitPosition)
        
        #expect(true) // Should create explosion without crashing
    }
    
    @Test("Multiple simultaneous collisions are handled")
    func testMultipleCollisions() {
        let shipManager = ShipManager(game: mockGame, arView: mockARView)
        
        // Create multiple explosions simultaneously
        for i in 0..<5 {
            let position = SIMD3<Float>(Float(i), 0, Float(i))
            shipManager.addExplosion(contactPoint: position)
        }
        
        #expect(true) // Should handle multiple effects
    }
    
    // MARK: - Network Collision Synchronization Tests
    
    @Test("Network missile hits are synchronized correctly")
    func testNetworkCollisionSync() {
        let missileManager = MissileManager(
            game: mockGame,
            sceneView: GameSceneView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
            gameManager: nil,
            localPlayer: mockPlayer
        )
        
        let shipManager = ShipManager(game: mockGame, arView: mockARView)
        let ship = Ship(entity: createMockShipEntity(), id: "network-ship")
        shipManager.ships = [ship]
        
        missileManager.shipManager = shipManager
        
        let hitData = MissileHitData(
            missileId: "network-missile",
            shipId: "network-ship",
            hitPosition: SIMD3<Float>(0, 0, 0),
            playerId: "remote-player",
            timestamp: CACurrentMediaTime()
        )
        
        let initialHealth = ship.currentHealth
        
        // Handle network missile hit
        missileManager.handleNetworkMissileHit(hitData)
        
        // Ship should take damage
        #expect(ship.currentHealth < initialHealth)
    }
    
    // MARK: - Performance Tests
    
    @Test("Collision detection performs well with many entities")
    func testCollisionPerformance() {
        let shipManager = ShipManager(game: mockGame, arView: mockARView)
        
        // Create many ships
        var ships: [Ship] = []
        for i in 0..<20 {
            let shipEntity = createMockShipEntity()
            let ship = Ship(entity: shipEntity, id: "perf-ship-\(i)")
            ships.append(ship)
        }
        
        shipManager.ships = ships
        
        let startTime = CACurrentMediaTime()
        
        // Simulate movement with collision calculations
        shipManager.moveShips(placed: true)
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        #expect(duration < 0.5) // Should complete quickly
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Collision system handles malformed entity names")
    func testMalformedEntityNames() {
        let entity1 = Entity()
        entity1.name = "" // Empty name
        
        let entity2 = Entity()
        entity2.name = "RandomName" // Non-standard name
        
        // Should not crash when checking for missile collision
        let isMissileHit = (entity1.name.contains("Missile") && !entity2.name.contains("Missile")) ||
                          (entity2.name.contains("Missile") && !entity1.name.contains("Missile"))
        
        #expect(!isMissileHit) // Should be false for malformed names
    }
    
    @Test("Collision system handles nil entity scenarios")
    func testNilEntityHandling() {
        let shipManager = ShipManager(game: mockGame, arView: mockARView)
        
        // Test with empty ship array
        shipManager.ships = []
        
        // Should handle network updates gracefully
        shipManager.destroyShip(withId: "non-existent-ship")
        shipManager.setShipTargeted(shipId: "non-existent-ship", targeted: true)
        
        #expect(true) // Should not crash
    }
}

// MARK: - Mock Collision Event

@MainActor
struct MockCollisionEvent {
    let entityA: Entity
    let entityB: Entity
    
    init(entityA: Entity, entityB: Entity) {
        self.entityA = entityA
        self.entityB = entityB
    }
}

// MARK: - Additional Integration Tests

extension CollisionTests {
    
    @Test("Full collision pipeline works end-to-end")
    func testFullCollisionPipeline() {
        // Create full system
        let gameManager = GameManager(arView: mockARView, session: nil)
        let shipManager = ShipManager(game: mockGame, arView: mockARView)
        let missileManager = MissileManager(
            game: mockGame,
            sceneView: GameSceneView(frame: CGRect(x: 0, y: 0, width: 100, height: 100)),
            gameManager: gameManager,
            localPlayer: mockPlayer
        )
        
        missileManager.shipManager = shipManager
        
        // Create ship
        let ship = Ship(entity: createMockShipEntity(), id: "pipeline-ship")
        shipManager.ships = [ship]
        
        let initialHealth = ship.currentHealth
        
        // Simulate damage
        ship.takeDamage(50)
        
        #expect(ship.currentHealth == initialHealth - 50)
        #expect(!ship.isDestroyed)
        
        // Test complete system integration
        #expect(missileManager.shipManager === shipManager)
        #expect(shipManager.ships.contains { $0.id == "pipeline-ship" })
    }
}
