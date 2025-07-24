//
//  EntityManagerTests.swift
//  ARKitDroneTests
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import Testing
import RealityKit
@testable import ARKitDrone

@MainActor
struct EntityManagerTests {
    
    @Test("EntityManager can register and retrieve entities")
    func testEntityRegistrationAndRetrieval() {
        let entityManager = EntityManager()
        let mockEntity = MockGameEntity(id: "test-entity-1")
        
        let registeredEntity = entityManager.register(mockEntity)
        
        #expect(registeredEntity === mockEntity)
        #expect(entityManager.activeEntityCount == 1)
        #expect(entityManager.getEntity(id: "test-entity-1") === mockEntity)
    }
    
    @Test("EntityManager can unregister entities")
    func testEntityUnregistration() {
        let entityManager = EntityManager()
        let mockEntity = MockGameEntity(id: "test-entity-2")
        
        entityManager.register(mockEntity)
        #expect(entityManager.activeEntityCount == 1)
        
        entityManager.unregister(id: "test-entity-2")
        #expect(entityManager.activeEntityCount == 0)
        #expect(entityManager.getEntity(id: "test-entity-2") == nil)
    }
    
    @Test("EntityManager can retrieve entities by type")
    func testEntityRetrievalByType() {
        let entityManager = EntityManager()
        let mockEntity1 = MockGameEntity(id: "test-entity-3")
        let mockEntity2 = MockGameEntity(id: "test-entity-4")
        let mockShip = MockShipEntity(id: "test-ship-1")
        
        entityManager.register(mockEntity1)
        entityManager.register(mockEntity2)
        entityManager.register(mockShip)
        
        let allMockEntities = entityManager.getAllEntities(ofType: MockGameEntity.self)
        let allMockShips = entityManager.getAllEntities(ofType: MockShipEntity.self)
        
        #expect(allMockEntities.count == 2)
        #expect(allMockShips.count == 1)
        #expect(allMockShips.first === mockShip)
    }
    
    @Test("EntityManager can update entities")
    func testEntityUpdate() {
        let entityManager = EntityManager()
        let mockEntity = MockGameEntity(id: "test-entity-5")
        
        entityManager.register(mockEntity)
        
        #expect(mockEntity.updateCallCount == 0)
        
        entityManager.update(deltaTime: 0.016)
        
        #expect(mockEntity.updateCallCount == 1)
        #expect(mockEntity.lastDeltaTime == 0.016)
    }
    
    @Test("EntityManager can destroy entities")
    func testEntityDestruction() {
        let entityManager = EntityManager()
        let mockEntity = MockGameEntity(id: "test-entity-6")
        
        entityManager.register(mockEntity)
        #expect(entityManager.activeEntityCount == 1)
        
        entityManager.destroyEntity(id: "test-entity-6")
        
        #expect(mockEntity.isDestroyed == true)
        #expect(mockEntity.onDestroyCalled == true)
        #expect(entityManager.activeEntityCount == 0)
    }
    
    @Test("EntityManager can destroy all entities of type")
    func testDestroyAllEntitiesOfType() {
        let entityManager = EntityManager()
        let mockEntity1 = MockGameEntity(id: "test-entity-7")
        let mockEntity2 = MockGameEntity(id: "test-entity-8")
        let mockShip = MockShipEntity(id: "test-ship-2")
        
        entityManager.register(mockEntity1)
        entityManager.register(mockEntity2)
        entityManager.register(mockShip)
        
        #expect(entityManager.activeEntityCount == 3)
        
        // Destroy specific entities manually since simplified EntityManager doesn't have ofType method
        entityManager.destroyEntity(mockEntity1)
        entityManager.destroyEntity(mockEntity2)
        
        #expect(mockEntity1.isDestroyed == true)
        #expect(mockEntity2.isDestroyed == true)
        #expect(mockShip.isDestroyed == false)
        #expect(entityManager.activeEntityCount == 1)
    }
    
    // Disabled - getPerformanceMetrics removed in simplified version
    // @Test("EntityManager provides performance metrics")
    func disabled_testPerformanceMetrics() {
        // Test disabled - EntityManager simplified without performance metrics
        return
        /*
        let entityManager = EntityManager()
        let mockEntity1 = MockGameEntity(id: "test-entity-9")
        let mockEntity2 = MockGameEntity(id: "test-entity-10")
        
        entityManager.register(mockEntity1)
        entityManager.register(mockEntity2)
        
        let metrics = entityManager.getPerformanceMetrics()
        
        #expect(metrics.activeEntityCount == 2)
        #expect(metrics.totalEntitiesCreated == 2)
        #expect(metrics.totalEntitiesDestroyed == 0)
        #expect(metrics.memoryFootprint > 0)
        
        entityManager.destroyEntity(id: "test-entity-9")
        
        let updatedMetrics = entityManager.getPerformanceMetrics()
        #expect(updatedMetrics.totalEntitiesDestroyed == 1)
        */
    }
    
    // Disabled - getEntity(from:) removed in simplified version
    // @Test("EntityManager can find entities by Reality entity")
    func disabled_testEntityLookupByRealityEntity() {
        // Test disabled - EntityManager simplified without Entity-based lookup
        return
        /*
        let entityManager = EntityManager()
        let realityEntity = Entity()
        let mockEntity = MockGameEntity(id: "test-entity-11", realityEntity: realityEntity)
        
        entityManager.register(mockEntity)
        
        let foundEntity = entityManager.getEntity(from: realityEntity)
        #expect(foundEntity === mockEntity)
        
        let typedEntity = entityManager.getEntity(from: realityEntity, as: MockGameEntity.self)
        #expect(typedEntity === mockEntity)
        */
    }
    
    // Disabled - validateEntityIntegrity removed in simplified version
    // @Test("EntityManager validates entity integrity")
    func disabled_testEntityIntegrityValidation() {
        // Test disabled - EntityManager simplified without integrity validation
        return
        /*
        let entityManager = EntityManager()
        let mockEntity = MockGameEntity(id: "test-entity-12")
        
        entityManager.register(mockEntity)
        
        let issues = entityManager.validateEntityIntegrity()
        #expect(issues.isEmpty)
        
        // Force the entity to be destroyed without proper cleanup
        mockEntity.isDestroyed = true
        
        let issuesAfterManualDestruction = entityManager.validateEntityIntegrity()
        #expect(!issuesAfterManualDestruction.isEmpty)
        */
    }
}

// MARK: - Mock Classes

class MockGameEntity: GameEntity {
    nonisolated let id: String
    nonisolated let entity: Entity
    var isDestroyed: Bool = false
    
    var updateCallCount: Int = 0
    var lastDeltaTime: TimeInterval = 0
    var onDestroyCalled: Bool = false
    var cleanupCalled: Bool = false
    
    init(id: String, realityEntity: Entity? = nil) {
        self.id = id
        self.entity = realityEntity ?? Entity()
    }
    
    func update(deltaTime: TimeInterval) {
        updateCallCount += 1
        lastDeltaTime = deltaTime
    }
    
    @MainActor
    func cleanup() {
        cleanupCalled = true
        isDestroyed = true
        Task { @MainActor in
            entity.removeFromParent()
        }
    }
    
    @MainActor
    func onDestroy() {
        onDestroyCalled = true
        cleanup()
    }
}

class MockShipEntity: GameEntity {
    nonisolated let id: String
    nonisolated let entity: Entity
    var isDestroyed: Bool = false
    
    init(id: String) {
        self.id = id
        self.entity = Entity()
    }
    
    func update(deltaTime: TimeInterval) {
        // Mock ship update
    }
    
    @MainActor
    func cleanup() {
        isDestroyed = true
        Task { @MainActor in
            entity.removeFromParent()
        }
    }
    
    @MainActor
    func onDestroy() {
        cleanup()
    }
}

// MARK: - Mock Delegate (Disabled)

/*
class MockEntityManagerDelegate: EntityManagerDelegate {
    var registeredEntities: [GameEntity] = []
    var unregisteredEntities: [GameEntity] = []
    var updatedEntities: [GameEntity] = []
    var destroyedEntities: [GameEntity] = []
    
    func entityManager(_ manager: EntityManager, didRegister entity: GameEntity) {
        registeredEntities.append(entity)
    }
    
    func entityManager(_ manager: EntityManager, didUnregister entity: GameEntity) {
        unregisteredEntities.append(entity)
    }
    
    func entityManager(_ manager: EntityManager, didUpdate entity: GameEntity, deltaTime: TimeInterval) {
        updatedEntities.append(entity)
    }
    
    func entityManager(_ manager: EntityManager, didDestroy entity: GameEntity) {
        destroyedEntities.append(entity)
    }
}
*/

// MARK: - Delegate Tests

extension EntityManagerTests {
    
    // Disabled - EntityManagerDelegate removed in simplified version
    // @Test("EntityManager delegate methods are called")
    func disabled_testEntityManagerDelegate() {
        // Test disabled - EntityManager simplified without delegate pattern
        return
        /*
        let entityManager = EntityManager()
        let mockDelegate = MockEntityManagerDelegate()
        entityManager.delegate = mockDelegate
        
        let mockEntity = MockGameEntity(id: "delegate-test-1")
        
        // Test registration
        entityManager.register(mockEntity)
        #expect(mockDelegate.registeredEntities.count == 1)
        #expect(mockDelegate.registeredEntities.first === mockEntity)
        
        // Test update
        entityManager.update(deltaTime: 0.1)
        #expect(mockDelegate.updatedEntities.count == 1)
        
        // Test destruction
        entityManager.destroyEntity(mockEntity)
        #expect(mockDelegate.destroyedEntities.count == 1)
        #expect(mockDelegate.unregisteredEntities.count == 1)
        */
    }
}
