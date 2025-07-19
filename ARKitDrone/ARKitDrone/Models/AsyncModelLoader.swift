//
//  AsyncModelLoader.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/19/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import RealityKit

@MainActor
class AsyncModelLoader {
    static let shared = AsyncModelLoader()
    private var loadingCache: [String: Task<Entity, Error>] = [:]
    
    private init() {} // Singleton
    
    func loadModel(named: String, withExtension ext: String = "usdz") async throws -> Entity {
        let fullName = "\(named).\(ext)"
        // Check if already loading
        if let existingTask = loadingCache[fullName] {
            return try await existingTask.value
        }
        // Create new loading task
        let task = Task<Entity, Error> {
            guard let url = Bundle.main.url(forResource: named, withExtension: ext) else {
                throw ModelLoadError.fileNotFound(fullName)
            }
            // Use async Entity initializer (NOT Entity.load)
            return try await Entity(contentsOf: url)
        }
        loadingCache[fullName] = task
        do {
            let entity = try await task.value
            loadingCache.removeValue(forKey: fullName)
            return entity
        } catch {
            loadingCache.removeValue(forKey: fullName)
            throw error
        }
    }
    
    // Alternative method using Entity(named:) async for Reality files
    func loadRealityModel(named: String) async throws -> Entity {
        let fullName = "\(named).reality"
        if let existingTask = loadingCache[fullName] {
            return try await existingTask.value
        }
        let task = Task<Entity, Error> {
            // Use async Entity(named:) for Reality files
            return try await Entity(named: named)
        }
        loadingCache[fullName] = task
        do {
            let entity = try await task.value
            loadingCache.removeValue(forKey: fullName)
            return entity
        } catch {
            loadingCache.removeValue(forKey: fullName)
            throw error
        }
    }
    
    // Preload models during app startup
    func preloadModels(_ modelNames: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for modelName in modelNames {
                group.addTask {
                    do {
                        _ = try await self.loadModel(named: modelName)
                        print("✅ Preloaded: \(modelName)")
                    } catch {
                        print("❌ Failed to preload: \(modelName) - \(error)")
                    }
                }
            }
        }
    }
}
