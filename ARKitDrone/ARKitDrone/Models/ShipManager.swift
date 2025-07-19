//
//  ShipManager.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import ARKit

enum ModelLoadError: Error {
    case fileNotFound(String)
    case loadingFailed(String)
}

@MainActor
class ShipManager {
    
    var game: Game
    var arView: ARView
    var ships: [Ship] = []
    var helicopterEntity: Entity?
    var targetIndex = 0
    var attack: Bool = false
    var shipsSetup: Bool = false
    
    struct LocalConstants {
        static let f35Scene = "F-35B_Lightning_II"
        static let f35Node = "F_35B"
    }
    
    init(game: Game, arView: ARView) {
        self.game = game
        self.arView = arView
    }
    
    // REPLACE setupShips() method:
    func setupShips() async {
        guard !shipsSetup else {
            print("⚠️ Ships already setup, skipping")
            return
        }
        
        do {
            // Use AsyncModelLoader
            let f35Entity = try await AsyncModelLoader.shared.loadModel(named: "F-35B_Lightning_II")
            
            // Create ships in parallel
            await withTaskGroup(of: Ship?.self) { group in
                for i in 1...3 {
                    group.addTask { @MainActor in
                        let shipEntity = f35Entity.clone(recursive: true)
                        shipEntity.name = "F_35B \(i)"
                        
                        let randomOffset = SIMD3<Float>(
                            x: Float.random(in: -20.0...20.0),
                            y: Float.random(in: -10.0...10.0),
                            z: Float.random(in: -20.0...40.0)
                        )
                        
                        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
                        anchor.addChild(shipEntity)
                        self.arView.scene.addAnchor(anchor)
                        
                        shipEntity.transform.translation = randomOffset
                        shipEntity.transform.scale = SIMD3<Float>(x: 0.005, y: 0.005, z: 0.005)
                        
                        let ship = Ship(entity: shipEntity)
                        ship.num = i
                        return ship
                    }
                }
                
                // Collect results
                for await ship in group {
                    if let ship = ship {
                        self.ships.append(ship)
                        print("🚢 Ship \(ship.num ?? 0) created")
                    }
                }
            }
            
            // Setup first target
            if !ships.isEmpty {
                let square = TargetNode()
                ships[0].square = square
                if let parent = ships[0].entity.parent {
                    parent.addChild(square)
                }
                ships[0].targetAdded = true
            }
            
            self.shipsSetup = true
            
            // Sync to GameSceneView
            if let gameRealityView = self.arView as? GameSceneView {
                gameRealityView.ships = self.ships
            }
            
        } catch {
            print("❌ Failed to load ship model: \(error)")
        }
    }
    
    func addTargetToShip() {
        if ships.count > targetIndex {
            targetIndex += 1
            if targetIndex < ships.count {
                if !ships[targetIndex].isDestroyed && !ships[targetIndex].targetAdded {
                    guard targetIndex < ships.count else { return }
                    let square = TargetNode()
                    ships[targetIndex].square = square
                    
                    // Add to ship's anchor
                    if let parent = ships[targetIndex].entity.parent {
                        parent.addChild(square)
                    }
                    
                    ships[targetIndex].targetAdded = true
                }
            }
        }
    }
    
    func addExplosion(contactPoint: SIMD3<Float>) {
        // Create simple explosion effect
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.02), materials: [SimpleMaterial(color: .orange, isMetallic: false)])
        let explosionAnchor = AnchorEntity(world: contactPoint)
        explosionAnchor.addChild(sphere)
        arView.scene.addAnchor(explosionAnchor)
        
        // Auto-remove after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            explosionAnchor.removeFromParent()
        }
    }
    
    func moveShips(placed: Bool) {
        // Skip distance culling for now - update all ships
        guard !ships.isEmpty else {
            print("❌ No ships to move")
            return
        }
        
        print("🚢 Moving \(ships.count) ships, placed: \(placed)")
        
        var perceivedCenter = SIMD3<Float>(0, 0, 0)
        var perceivedVelocity = SIMD3<Float>(0, 0, 0)
        
        for otherShip in ships {
            perceivedCenter = perceivedCenter + otherShip.entity.transform.translation
            perceivedVelocity = perceivedVelocity + otherShip.velocity
        }
        
        //        // Get helicopter position for orbiting behavior
        //        let helicopterPos = helicopterEntity?.transform.translation ?? SIMD3<Float>(0, 0, 0)
        //        let cameraTransform = arView.session.currentFrame?.camera.transform ?? matrix_identity_float4x4
        //        let cameraPos = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)
        //
        // Update all ships
        ships.forEach { ship in
            ship.updateShipPosition(
                perceivedCenter: perceivedCenter,
                perceivedVelocity: perceivedVelocity,
                otherShips: ships,
                obstacles: helicopterEntity != nil ? [helicopterEntity!] : []
            )
        }
        
        if placed {
            _ = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { [weak self] timer in
                guard let self = self else { return }
                Task { @MainActor in
                    self.attack = true
                }
                timer.invalidate()
            }
            
            for ship in ships {
                if attack {
                    if let helicopterEntity = helicopterEntity {
                        ship.attack(target: helicopterEntity)
                    }
                    _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] timer in
                        guard let self = self else { return }
                        Task { @MainActor in
                            self.attack = false
                        }
                        timer.invalidate()
                    }
                }
            }
        }
    }
}

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
