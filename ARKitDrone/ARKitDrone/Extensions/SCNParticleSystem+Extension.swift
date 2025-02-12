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
        explosion.emitterShape = SCNSphere(radius: 3)
        explosion.birthRate = 2500
        explosion.emissionDuration = 0.1
        explosion.spreadingAngle = 360
        explosion.particleLifeSpan = 0.1
        explosion.particleLifeSpanVariation = 0.1
        explosion.particleVelocity = 3.0
        explosion.particleVelocityVariation = 1.5
        explosion.particleSize = 0.04
        explosion.particleColor = UIColor.red
        explosion.particleImage = UIImage(named: "spark")
        explosion.isAffectedByGravity = true
        explosion.blendMode = .additive
        explosion.particleIntensity = 2
        return explosion
    }
}
