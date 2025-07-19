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
        explosion.emitterShape = SCNSphere(radius: 3.0)
        explosion.birthRate = 6000
        explosion.emissionDuration = 0.01
        explosion.particleLifeSpan = 0.04
        explosion.particleLifeSpanVariation = 0.3
        explosion.particleVelocity = 15
        explosion.particleVelocityVariation = 4.0
        explosion.spreadingAngle = 360
        explosion.particleSize = 0.03
        explosion.particleSizeVariation = 0.05
        explosion.particleAngularVelocity = 5.0
        explosion.particleAngularVelocityVariation = 5.5
        explosion.particleColor = UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 1.0)
        explosion.particleColorVariation = SCNVector4(0.2, 0.2, 0.2, 0.5)
        let fadeAnimation = CAKeyframeAnimation(keyPath: "opacity")
        fadeAnimation.values = [1.0, 0.0]
        fadeAnimation.keyTimes = [0.0, 0.5] as [NSNumber]
        fadeAnimation.duration = explosion.particleLifeSpan
        explosion.propertyControllers = [
            SCNParticleSystem.ParticleProperty.opacity: SCNParticlePropertyController(animation: fadeAnimation)
        ]
        explosion.particleImage = UIImage(named: "spark.png")
        explosion.isAffectedByGravity = true
        explosion.acceleration = SCNVector3(0, -15.8, 0)
        explosion.blendMode = .additive
        explosion.dampingFactor = 0.9
        return explosion
    }
}

