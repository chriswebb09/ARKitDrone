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
        // RealityKit doesn't support SceneKit-style particle systems
        // You need to use a custom 3D animation, sound, or a visual trick instead.
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(
                color: .orange,
                isMetallic: false
            )]
        )
        let explosionAnchor = AnchorEntity(world: position)
        explosionAnchor.addChild(sphere)
        scene.anchors.append(explosionAnchor)
        // Auto-remove after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            explosionAnchor.removeFromParent()
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
