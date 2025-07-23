//
//  GameSceneView.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import RealityKit
import UIKit

class GameSceneView: ARView {
    
    struct LocalConstants {
        static let sceneName = "Scene2.usdz"
        static let f35Scene = "F-35B_Lightning_II.usdz"
        static let f35Node = "F_35B_Lightning_II"
        static let tankAssetName = "m1tankmodel"
    }
    
    var ships: [Ship] = []
    var tank: M1AbramsTank!
    var targetIndex = 0
    var attack: Bool = false
    
    // Legacy helicopter properties removed - now handled by HelicopterObject system
    // All helicopter management is done through GameManager.helicopters
    
    private func preloadModelsAsnyc() {
        automaticallyConfigureSession = false
        // Start preloading models immediately
        Task.detached {
            await AsyncModelLoader.shared.preloadModels([
                "F-35B_Lightning_II",  // USDZ files
                "m1tankmodel"
            ])
            // Preload Reality files separately
            do {
                try await AsyncModelLoader.shared.loadRealityModel(named: "heli")
                print("Preloaded: heli.reality")
            } catch {
                print("Failed to preload heli: \(error)")
            }
        }
    }
    
    // Legacy loadHelicopter removed - helicopters now created through HelicopterObject system
    
    func setup() async {
        preloadModelsAsnyc()
        await setupTank()
    }
    
    @MainActor
    private func setupTank() async {
        tank = M1AbramsTank()
        // Tank will be positioned when placed via placeTankOnSurface
    }
    
    // Legacy positionHelicopter removed - positioning now handled by HelicopterObject system
    
    func addExplosion(at position: SIMD3<Float>) {
        print("💥 EXPLOSION at position: \(position)")
        
        let explosionAnchor = AnchorEntity(world: position)
        
        // Create a burst of small glowing spheres for particle-like effect
        for i in 0..<20 {
            let particle = ModelEntity(
                mesh: .generateSphere(radius: Float.random(in: 0.05...0.15)),
                materials: [UnlitMaterial(color: UIColor(
                    red: CGFloat(Float.random(in: 0.8...1.0)),     // Bright red-orange
                    green: CGFloat(Float.random(in: 0.3...0.8)),   // Medium orange-yellow
                    blue: CGFloat(Float.random(in: 0.0...0.2)),    // Little to no blue
                    alpha: CGFloat(Float.random(in: 0.7...1.0))
                ))]
            )
            
            // Random burst direction
            let direction = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -0.5...1),  // Slightly upward bias
                Float.random(in: -1...1)
            )
            let distance = Float.random(in: 0.5...2.0)
            particle.transform.translation = simd_normalize(direction) * distance
            
            explosionAnchor.addChild(particle)
            
            // Animate each particle moving outward
            Task { @MainActor in
                let moveAnimation = FromToByAnimation<Transform>(
                    name: "particleMove",
                    from: Transform(translation: SIMD3<Float>(0, 0, 0)),
                    to: Transform(translation: particle.transform.translation * 2.0),
                    duration: 0.8,
                    timing: .easeOut,
                    bindTarget: .transform
                )
                
                if let animationResource = try? AnimationResource.generate(with: moveAnimation) {
                    particle.playAnimation(animationResource)
                }
            }
        }
        
        // Add a bright flash at the center
        let flash = ModelEntity(
            mesh: .generateSphere(radius: 0.8),
            materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.9))]
        )
        explosionAnchor.addChild(flash)
        
        // Animate the flash quickly expanding and fading
        Task { @MainActor in
            let flashAnimation = FromToByAnimation<Transform>(
                name: "flash",
                from: Transform(scale: SIMD3<Float>(repeating: 0.1)),
                to: Transform(scale: SIMD3<Float>(repeating: 3.0)),
                duration: 0.2,
                timing: .easeOut,
                bindTarget: .transform
            )
            
            if let animationResource = try? AnimationResource.generate(with: flashAnimation) {
                flash.playAnimation(animationResource)
            }
            
            // Make flash disappear quickly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                flash.removeFromParent()
            }
        }
        
        scene.anchors.append(explosionAnchor)
        print("💥 Particle explosion effect added to scene")
        
        // Remove explosion after particles have spread
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            explosionAnchor.removeFromParent()
            print("💥 Explosion effect removed")
        }
    }
    
    func placeTankOnSurface(at screenPoint: CGPoint) {
        guard let tank = tank else {
            print("❌ No tank available to place")
            return
        }
        
        // Use raycast to find surface
        let raycastResults = self.raycast(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        
        if let result = raycastResults.first {
            let tankTransform = result.worldTransform
            Task {
                await tank.setup(with: self, transform: tankTransform)
                print("✅ M1 Abrams Tank placed successfully")
            }
        }
    }
}
