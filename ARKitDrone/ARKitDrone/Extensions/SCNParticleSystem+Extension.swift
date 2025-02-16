//
//  SCNParticleSystem+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNParticleSystem {
    
    static func createExplosion() -> SCNParticleSystem {
        let explosion = SCNParticleSystem()
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
        explosion.particleImage = UIImage(named: "spark")
        explosion.isAffectedByGravity = false
        explosion.blendMode = .additive
        explosion.particleColor = UIColor.orange.withAlphaComponent(1.0)
        explosion.particleColorVariation = SCNVector4(0.1, 0.1, 0.1, 0.5)
        explosion.particleLifeSpan = 0.5
        explosion.particleLifeSpanVariation = 0.3
        explosion.dampingFactor = 1.2
        return explosion
    }
}

