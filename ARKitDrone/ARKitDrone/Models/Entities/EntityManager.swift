//
//  EntityManager.swift
//  ARKitDrone
//
//  Simplified entity management system
//

import Foundation
import RealityKit
import UIKit

// MARK: - Game Entity Protocol (Simplified)

@MainActor
public protocol GameEntity: AnyObject {
    var id: String { get }
    var entity: Entity { get }
    var isDestroyed: Bool { get set }
    
    func update(deltaTime: TimeInterval)
    func cleanup()
    func onDestroy()
}

// MARK: - Default Implementation

@MainActor
public extension GameEntity {
    func update(deltaTime: TimeInterval) {
        // Default implementation - entities can override
    }
    
    func cleanup() {
        isDestroyed = true
        entity.removeFromParent()
    }
    
    func onDestroy() {
        cleanup()
    }
}

// MARK: - Simplified Entity Manager

@MainActor
public class EntityManager {
    
    // MARK: - Properties
    
    private var entities: [String: GameEntity] = [:]
    private var lastUpdateTime: TimeInterval = CACurrentMediaTime()
    
    var activeEntityCount: Int {
        return entities.count
    }
    
    // MARK: - Registration
    
    func register<T: GameEntity>(_ entity: T) -> T {
        entities[entity.id] = entity
        return entity
    }
    
    func unregister(id: String) {
        entities.removeValue(forKey: id)
    }
    
    func unregister(_ entity: GameEntity) {
        unregister(id: entity.id)
    }
    
    // MARK: - Lookup Methods
    
    func getEntity(id: String) -> GameEntity? {
        return entities[id]
    }
    
    func getEntity<T: GameEntity>(id: String, as type: T.Type) -> T? {
        return entities[id] as? T
    }
    
    func getAllEntities() -> [GameEntity] {
        return Array(entities.values)
    }
    
    func getAllEntities<T: GameEntity>(ofType type: T.Type) -> [T] {
        return entities.values.compactMap { $0 as? T }
    }
    
    // MARK: - Update Cycle
    
    func update(deltaTime: TimeInterval) {
        // Update all entities
        for entity in entities.values {
            guard !entity.isDestroyed else { continue }
            entity.update(deltaTime: deltaTime)
        }
        
        // Cleanup destroyed entities
        let destroyedIds = entities.compactMap { (id, entity) in
            entity.isDestroyed ? id : nil
        }
        
        for id in destroyedIds {
            unregister(id: id)
        }
    }
    
    // MARK: - Destruction
    
    func destroyEntity(id: String) {
        guard let entity = entities[id] else { return }
        destroyEntity(entity)
    }
    
    func destroyEntity(_ entity: GameEntity) {
        guard !entity.isDestroyed else { return }
        entity.onDestroy()
        unregister(entity)
    }
    
    func destroyAllEntities() {
        let allEntities = Array(entities.values)
        for entity in allEntities {
            destroyEntity(entity)
        }
    }
}
