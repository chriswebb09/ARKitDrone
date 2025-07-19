//
//  ShipManager.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import ARKit

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
    
    func setupShips() {
        // Prevent duplicate ship creation
        guard !shipsSetup else {
            print("⚠️ Ships already setup, skipping")
            return
        }
        
        Task {
            do {
                let f35Entity = try await Entity.loadUSDZ(named: LocalConstants.f35Scene, in: .main)
                
                // Create all ships at once on main actor
                await MainActor.run {
                    for i in 1...3 {
                        let shipEntity = f35Entity.clone(recursive: true)
                        shipEntity.name = "F_35B \(i)"
                        
                        let randomOffset = SIMD3<Float>(
                            x: Float.random(in: -20.0...20.0),
                            y: Float.random(in: -10.0...10.0),
                            z: Float.random(in: -20.0...40.0)
                        )
                        
                        // Create anchor at world origin and position ship directly
                        let anchor = AnchorEntity(world: SIMD3<Float>(0, 0, 0))
                        anchor.addChild(shipEntity)
                        arView.scene.addAnchor(anchor)
                        
                        // Position ship at the random offset in world space
                        shipEntity.transform.translation = randomOffset
                        shipEntity.transform.scale = SIMD3<Float>(x: 0.005, y: 0.005, z: 0.005)
                        
                        let ship = Ship(entity: shipEntity)
                        ship.num = i
                        
                        self.ships.append(ship)
                        print("🚢 Ship \(i) created: destroyed = \(ship.isDestroyed), position = \(shipEntity.transform.translation)")
                        
                        if i == 1 {
                            self.targetIndex = 0
                            // Only create target if one doesn't already exist
                            if ship.square == nil && !ship.targetAdded {
                                let square = TargetNode()
                                ship.square = square
                                anchor.addChild(square)
                                ship.targetAdded = true
                            }
                        }
                    }
                    self.shipsSetup = true
                    print("✅ All 3 ships created successfully")
                    
                    // Sync ships to arView for MissileManager access
                    if let gameRealityView = self.arView as? GameSceneView {
                        gameRealityView.ships = self.ships
                        print("🔄 Ships synced to GameRealityView: \(gameRealityView.ships.count)")
                    }
                }
            } catch {
                print("❌ Failed to load ship model: \(error)")
                return
            }
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
