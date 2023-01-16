//
//  SCNPhysicsBody+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/16/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNPhysicsBody {
    
    var simdVelocity: SIMD3<Float> {
        get {
            return SIMD3<Float>(velocity)
        }
        set {
            velocity = SCNVector3(newValue)
        }
    }
    
    var simdAngularVelocity: SIMD4<Float> {
        get {
            return SIMD4<Float>(angularVelocity)
        }
        set {
            angularVelocity = SCNVector4(newValue)
        }
    }
    
    var simdVelocityFactor: SIMD3<Float> {
        get {
            return SIMD3<Float>(velocityFactor)
        }
        set {
            velocityFactor = SCNVector3(newValue)
        }
    }
    
    var simdAngularVelocityFactor: SIMD3<Float> {
        get {
            return SIMD3<Float>(angularVelocityFactor)
        }
        set {
            angularVelocityFactor = SCNVector3(newValue)
        }
    }
    
    func applyForce(_ force: SIMD3<Float>, asImpulse impulse: Bool) {
        applyForce(SCNVector3(force), asImpulse: impulse)
    }
    
    func applyTorque(_ torque: SIMD4<Float>, asImpulse impulse: Bool) {
        applyTorque(SCNVector4(torque), asImpulse: impulse)
    }
}
