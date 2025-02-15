//
//  SCNParticleSystem+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNNode {
    func removeAll() {
        isHidden = true
        removeAllAnimations()
        removeAllActions()
        removeAllParticleSystems()
        removeFromParentNode()
    }
}

extension SCNParticleSystem {
    
    static func createExplosion() -> SCNParticleSystem {
        let explosion = SCNParticleSystem()
        
        // Basic properties
        explosion.emitterShape = SCNSphere(radius: 4)
        explosion.birthRate = 3000
        explosion.emissionDuration = 0.15
        explosion.spreadingAngle = 360
        explosion.particleLifeSpan = 0.3
        explosion.particleLifeSpanVariation = 0.2
        explosion.particleVelocity = 5.0
        explosion.particleVelocityVariation = 2.5
        explosion.particleSize = 0.08
        explosion.particleSizeVariation = 0.05
        explosion.particleColor = UIColor.orange
        explosion.particleImage = UIImage(named: "spark") // Use a detailed fire/smoke texture
        explosion.isAffectedByGravity = false
        explosion.blendMode = .additive
        
        // Opacity fade-out
        explosion.particleColor = UIColor.orange.withAlphaComponent(1.0)  // Set initial alpha
        explosion.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.5) // Add randomness
        explosion.particleLifeSpan = 0.5 // Base lifespan
        explosion.particleLifeSpanVariation = 0.3
        
        // Add damping to slow particles
        explosion.dampingFactor = 1.2
        
        return explosion
    }
    
    //    static func createExplosion() -> SCNParticleSystem {
    //        let explosion = SCNParticleSystem()
    //        explosion.emitterShape = SCNSphere(radius: 5)
    //        explosion.birthRate = 2500
    //        explosion.emissionDuration = 0.1
    //        explosion.spreadingAngle = 360
    //        explosion.particleLifeSpan = 0.1
    //        explosion.particleLifeSpanVariation = 0.1
    //        explosion.particleVelocity = 3.0
    //        explosion.particleVelocityVariation = 1.5
    //        explosion.particleSize = 0.04
    //        explosion.particleColor = UIColor.systemOrange
    //        explosion.particleImage = UIImage(named: "spark")
    //        explosion.isAffectedByGravity = true
    //        explosion.blendMode = .additive
    //        explosion.particleIntensity = 2
    //        return explosion
    //    }
    
}

