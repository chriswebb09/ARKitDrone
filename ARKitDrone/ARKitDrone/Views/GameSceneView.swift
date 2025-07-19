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
    var helicopter: ApacheHelicopter!
    var tankEntity: ModelEntity!
    var tankAnchor: AnchorEntity!
    var helicopterAnchor: AnchorEntity!
    var targetIndex = 0
    var attack: Bool = false
    var competitor: ApacheHelicopter!
    
    func setup() async {
        automaticallyConfigureSession = false
        // Start preloading models immediately
        Task.detached {
            await AsyncModelLoader.shared.preloadModels([
                "F-35B_Lightning_II",  // USDZ files
                "m1tankmodel"
            ])
            // Preload Reality files separately
            do {
                _ = try await AsyncModelLoader.shared.loadRealityModel(named: "heli")
                print("✅ Preloaded: heli.reality")
            } catch {
                print("❌ Failed to preload heli: \(error)")
            }
        }
        // Load helicopter async
        Task { @MainActor in
            let heli = await ApacheHelicopter()
            await heli.setup()
            self.helicopter = heli
        }
        // Load tank async
        Task { @MainActor in
            do {
                let entity = try await AsyncModelLoader.shared.loadModel(named: "m1tankmodel")
                let tankRootEntity: Entity
                if let rootEntity = entity.findEntity(named: "root") {
                    tankRootEntity = rootEntity
                } else {
                    tankRootEntity = entity
                }
                tankRootEntity.name = "Tank"
                tankRootEntity.scale = SIMD3<Float>(repeating: 0.1)
                tankRootEntity.isEnabled = true
                tankRootEntity.transform.rotation = simd_quatf(
                    angle: -Float.pi / 2,
                    axis: SIMD3<Float>(1, 0, 0)
                )
                if let bodyEntity = tankRootEntity.findEntity(named: "body") {
                    let bounds = bodyEntity.visualBounds(relativeTo: nil).extents
                    bodyEntity.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
                    bodyEntity.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static))
                }
                if let modelEntity = tankRootEntity as? ModelEntity {
                    self.tankEntity = modelEntity
                } else {
                    let wrapperEntity = ModelEntity()
                    wrapperEntity.name = "TankWrapper"
                    wrapperEntity.addChild(tankRootEntity)
                    self.tankEntity = wrapperEntity
                }
            } catch {
                print("❌ Failed to load tank model: \(error)")
            }
        }
    }
    
    // UPDATE positionHelicopter method:
    func positionHelicopter(at position: SIMD3<Float>) async -> ApacheHelicopter? {
        if helicopter == nil {
            helicopter = await ApacheHelicopter()
        }
        if helicopter?.helicopter == nil {
            await helicopter?.setup()
        }
        guard let heliEntity = helicopter.helicopter else {
            print("🚫 Helicopter entity not loaded after setup.")
            return nil
        }
        helicopterAnchor?.removeFromParent()
        let helicopterPosition = SIMD3<Float>(
            x: position.x,
            y: position.y + 0.5,
            z: position.z - 0.2
        )
        helicopterAnchor = AnchorEntity(world: helicopterPosition)
        heliEntity.position = .zero
        helicopterAnchor?.addChild(heliEntity)
        if let anchor = helicopterAnchor {
            scene.anchors.append(anchor)
        }
        helicopter.setupHUD()
        return helicopter
    }
    
    
    func addExplosion(at position: SIMD3<Float>) {
        // RealityKit doesn't support SceneKit-style particle systems
        // You need to use a custom 3D animation, sound, or a visual trick instead.
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.02),
            materials: [SimpleMaterial(color: .orange, isMetallic: false)]
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
        // Force load tank if not ready
        if tankEntity == nil {
            print("🚛 Loading tank synchronously...")
            return
        }
        guard let tankEntity = tankEntity else {
            print("❌ No tank entity available to place")
            return
        }
        // Don't place if already placed
        if tankAnchor != nil {
            print("⚠️ Tank already placed")
            return
        }
        // Use raycast to find surface
        let raycastResults = self.raycast(
            from: screenPoint,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        if let result = raycastResults.first {
            let tankPosition = SIMD3<Float>(
                result.worldTransform.columns.3.x,
                result.worldTransform.columns.3.y,
                result.worldTransform.columns.3.z
            )
            let adjustedPosition = SIMD3<Float>(
                tankPosition.x,
                tankPosition.y + 0.05,
                tankPosition.z
            )
            // Create anchor for tank
            tankAnchor = AnchorEntity(world: adjustedPosition)
            tankAnchor!.addChild(tankEntity)
            scene.addAnchor(tankAnchor!)
        }
    }
}
