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
import Foundation
import simd

// MARK: - Explosion Configuration (Moved to GameSceneView file for compilation)

struct ExplosionConfig {
    static let shared = ExplosionConfig()
    
    // Particle settings
    let particleCount: Int = 20
    let particleRadiusRange: ClosedRange<Float> = 0.05...0.15
    let particleDistanceRange: ClosedRange<Float> = 0.5...2.0
    let particleAnimationDuration: TimeInterval = 0.8
    let particleSpreadMultiplier: Float = 2.0
    
    // Color settings
    let explosionColors = ExplosionColorConfig(
        redRange: 0.8...1.0,
        greenRange: 0.3...0.8,
        blueRange: 0.0...0.2,
        alphaRange: 0.7...1.0
    )
    
    // Flash settings
    let flashRadius: Float = 0.8
    let flashInitialScale: Float = 0.1
    let flashFinalScale: Float = 3.0
    let flashDuration: TimeInterval = 0.2
    let flashColor = UIColor(red: 1.0, green: 1.0, blue: 0.9, alpha: 0.9)
    
    // Cleanup settings
    let explosionLifetime: TimeInterval = 1.0
    
    // Direction bias
    let upwardBias: ClosedRange<Float> = -0.5...1.0
}

struct ExplosionColorConfig {
    let redRange: ClosedRange<Float>
    let greenRange: ClosedRange<Float>
    let blueRange: ClosedRange<Float>
    let alphaRange: ClosedRange<Float>
    
    func randomColor() -> UIColor {
        return UIColor(
            red: CGFloat(Float.random(in: redRange)),
            green: CGFloat(Float.random(in: greenRange)),
            blue: CGFloat(Float.random(in: blueRange)),
            alpha: CGFloat(Float.random(in: alphaRange))
        )
    }
}

// MARK: - Explosion Effect Manager (Moved to GameSceneView file for compilation)

@MainActor
class ExplosionEffectManager {
    
    private let config: ExplosionConfig
    private weak var scene: RealityKit.Scene?
    
    init(scene: RealityKit.Scene, config: ExplosionConfig = .shared) {
        self.scene = scene
        self.config = config
    }
    
    func createExplosion(at position: SIMD3<Float>) {
        guard let scene = scene else {
            print("⚠️ ExplosionEffectManager: Scene not available")
            return
        }
        
        print("💥 Creating explosion at position: \(position)")
        
        let explosionAnchor = AnchorEntity(world: position)
        createParticleBurst(in: explosionAnchor)
        createFlashEffect(in: explosionAnchor)
        scene.anchors.append(explosionAnchor)
        scheduleCleanup(for: explosionAnchor)
        
        print("💥 Explosion effect added to scene")
    }
    
    private func createParticleBurst(in anchor: AnchorEntity) {
        for _ in 0..<config.particleCount {
            let particle = createParticle()
            let direction = generateRandomDirection()
            let distance = Float.random(in: config.particleDistanceRange)
            
            particle.transform.translation = simd_normalize(direction) * distance
            anchor.addChild(particle)
            animateParticle(particle)
        }
    }
    
    private func createParticle() -> ModelEntity {
        let radius = Float.random(in: config.particleRadiusRange)
        let color = config.explosionColors.randomColor()
        
        return ModelEntity(
            mesh: .generateSphere(radius: radius),
            materials: [UnlitMaterial(color: color)]
        )
    }
    
    private func generateRandomDirection() -> SIMD3<Float> {
        return SIMD3<Float>(
            Float.random(in: -1...1),
            Float.random(in: config.upwardBias),
            Float.random(in: -1...1)
        )
    }
    
    private func animateParticle(_ particle: ModelEntity) {
        Task { @MainActor in
            let finalPosition = particle.transform.translation * config.particleSpreadMultiplier
            
            let moveAnimation = FromToByAnimation<Transform>(
                name: "particleMove",
                from: Transform(translation: SIMD3<Float>(0, 0, 0)),
                to: Transform(translation: finalPosition),
                duration: config.particleAnimationDuration,
                timing: .easeOut,
                bindTarget: .transform
            )
            
            if let animationResource = try? AnimationResource.generate(with: moveAnimation) {
                particle.playAnimation(animationResource)
            }
        }
    }
    
    private func createFlashEffect(in anchor: AnchorEntity) {
        let flash = ModelEntity(
            mesh: .generateSphere(radius: config.flashRadius),
            materials: [UnlitMaterial(color: config.flashColor)]
        )
        
        anchor.addChild(flash)
        animateFlash(flash)
    }
    
    private func animateFlash(_ flash: ModelEntity) {
        Task { @MainActor in
            let flashAnimation = FromToByAnimation<Transform>(
                name: "flash",
                from: Transform(scale: SIMD3<Float>(repeating: config.flashInitialScale)),
                to: Transform(scale: SIMD3<Float>(repeating: config.flashFinalScale)),
                duration: config.flashDuration,
                timing: .easeOut,
                bindTarget: .transform
            )
            
            if let animationResource = try? AnimationResource.generate(with: flashAnimation) {
                flash.playAnimation(animationResource)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + config.flashDuration) {
                flash.removeFromParent()
            }
        }
    }
    
    private func scheduleCleanup(for anchor: AnchorEntity) {
        DispatchQueue.main.asyncAfter(deadline: .now() + config.explosionLifetime) {
            anchor.removeFromParent()
            print("💥 Explosion effect cleaned up")
        }
    }
    
    func createMinorExplosion(at position: SIMD3<Float>) {
        // Create a scaled-down version
        let minorConfig = ExplosionConfig()
        // Would implement minor explosion variant here
        createExplosion(at: position)
    }
    
    func createMajorExplosion(at position: SIMD3<Float>) {
        // Create a scaled-up version
        let majorConfig = ExplosionConfig()
        // Would implement major explosion variant here
        createExplosion(at: position)
    }
}

class GameSceneView: ARView {
    
    struct LocalConstants {
        static let sceneName = "Scene2.usdz"
        static let f35Scene = "F-35B_Lightning_II.usdz"
        static let f35Node = "F_35B_Lightning_II"
        static let tankAssetName = "m1tankmodel"
    }
    
    // MARK: - Effect Managers
    
    private lazy var explosionEffectManager = ExplosionEffectManager(scene: scene)
    
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
    
    // MARK: - Explosion Effects
    
    /// Create a standard explosion effect at the specified position
    func addExplosion(at position: SIMD3<Float>) {
        explosionEffectManager.createExplosion(at: position)
    }
    
    /// Create a minor explosion effect for smaller impacts
    func addMinorExplosion(at position: SIMD3<Float>) {
        explosionEffectManager.createMinorExplosion(at: position)
    }
    
    /// Create a major explosion effect for larger impacts  
    func addMajorExplosion(at position: SIMD3<Float>) {
        explosionEffectManager.createMajorExplosion(at: position)
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
