//
//  Helicopter.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import simd

class ApacheHelicopter {
    
    // MARK: - LocalConstants
    
    struct LocalConstants {
        static let sceneName = "art.scnassets/Apache.scn"
        static let parentModelName = "grpApache"
        static let bodyName = "Body"
        static let wingLName = "Wing_L"
        static let wingRName = "Wing_R"
        static let frontRotorName = "FrontRotor"
        static let tailRotorName = "TailRotor"
        static let hudNodeName = "hud"
        static let frontIRSteering = "FrontIRSteering"
        
        static let missile1 = "Missile1"
        static let missile2 = "Missile2"
        static let missile3 = "Missile3"
        static let missile4 = "Missile4"
        static let missile5 = "Missile5"
        static let missile6 = "Missile6"
        static let missile7 = "Missile7"
        static let missile8 = "Missile8"
        
        static let frontIR = "FrontIR"
        static let audioFileName = "audio.m4a"
        static let upperGun = "UpperGun"
        
        static let activeEmitterRate: CGFloat = 1000
        static let angleConversion = SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float.pi, z: 0 , w: 0)
        static let negativeAngleConversion = SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float.pi, z: 0 , w: 0)
        static let altitudeAngleConversion = SCNQuaternion.angleConversion(x: 0.001 * Float.pi, y:0, z: 0 , w: 0)
        static let negativeAltitudeAngleConversion = SCNQuaternion.angleConversion(x: -0.001 * Float.pi, y:0, z: 0 , w: 0)
    }
    
    var helicopterNode: SCNNode!
    var parentModelNode: SCNNode!
    var firing:Bool = false
    
    var missile1: Missile!
    var currentMissile: Missile!
    var missile2: Missile!
    var missile3: Missile!
    var missile4: Missile = Missile()
    var missile5: Missile = Missile()
    var missile6: Missile = Missile()
    var missile7: Missile = Missile()
    var missile8: Missile = Missile()
    var missiles: [Missile] = []
    
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var wingL: SCNNode!
    var wingR: SCNNode!
    var hud: SCNNode!
    var front: SCNNode!
    var frontIR: SCNNode!
    var missilesArmed: Bool = false
    var missileLockDirection = SCNVector3(0, 0, 1)
    var upperGun: SCNNode!
    
    var targetPosition: SCNVector3!
    
    func spinBlades() {
        DispatchQueue.global(qos: .userInteractive).async {
            let rotate = SCNAction.rotateBy(x: 20, y: 0, z: 0, duration: 0.5)
            let moveSequence = SCNAction.sequence([rotate])
            let moveLoop = SCNAction.repeatForever(moveSequence)
            let rotate2 = SCNAction.rotateBy(x: 0, y: 20, z: 0, duration: 0.25)
            let moveSequence2 = SCNAction.sequence([rotate2])
            let moveLoop2 = SCNAction.repeatForever(moveSequence2)
            DispatchQueue.main.async {
                self.rotor2.runAction(moveLoop)
                self.rotor.runAction(moveLoop2)
            }
        }
    }
    
    func setup(with helicopterNode: SCNNode) {
        helicopterNode.simdScale = SIMD3<Float>(0.001, 0.001, 0.001)
        hud.simdScale = SIMD3<Float>(0.1, 0.1, 0.1)
        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: helicopterNode.position.z)
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-0.44))
        spinBlades()
    }
    
    func toggleArmMissile() {
        missilesArmed = !missilesArmed
    }
    
    func missilesAreArmed() -> Bool {
        return missilesArmed
    }
    
    func rotate(value: Float) {
        guard helicopterNode != nil else { return }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        let localAngleConversion = SCNQuaternion.angleConversion(x: 0, y:  -(0.35 * value) * Float(Double.pi), z: 0, w: 0)
        let locationRotation = SCNQuaternion.getQuaternion(from: localAngleConversion)
        helicopterNode.localRotate(by: locationRotation)
        updateHUD()
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-0.44))
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        guard helicopterNode != nil else { return }
        let val = value / 8
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y: 0, z: -val))
        updateHUD()
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-0.44))
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        guard helicopterNode != nil else { return }
        let val = (value / 30.0)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y:val, z:0))
        updateHUD()
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-0.44))
        SCNTransaction.commit()
    }
    
    func updateHUD() {
        hud.orientation = helicopterNode.orientation
        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: helicopterNode.position.z)
    }
    
    func moveSides(value: Float) {
        guard helicopterNode != nil else { return }
        let val = -(value / 150)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: val, y: 0, z: 0))
        updateHUD()
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-0.44))
        SCNTransaction.commit()
    }
    
    
    var speed: Float = 2000 // Base speed
    let maxSpeed: Float = 10000.0 // Max missile speed
    // Define smooth factors for rotation
    let rotationSmoothFactor: Float = 0.005 // Lower = smoother turns
    
    
    func lockOn(ship: Ship) {
        guard helicopterNode != nil else { return }
        let target = ship.node
        targetPosition = target.position
        let helicopterNodePosition = helicopterNode.position
        hud.position = SCNVector3(x: helicopterNodePosition.x, y: helicopterNodePosition.y , z: helicopterNodePosition.z)
        hud.orientation = target.orientation
        hud.look(at: target.position)
        let distance = helicopterNode.position.distance(target.position) - 4
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z: -distance))
        SCNTransaction.commit()
    }
    
    static var speed: Float = 50
    
    func update(missile: Missile, ship: Ship, offset: Int = 1, previousTime: CFAbsoluteTime) -> CFAbsoluteTime {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = max(Float(currentTime - previousTime), 1.0 / 120.0)
        let nextTime = currentTime
        let missilePosition = missile.node.presentation.simdPosition
        let shipPosition = ship.node.simdPosition
        let targetDirection = simd_normalize(shipPosition - missilePosition)
        let currentDirection = missile.node.simdOrientation.act(simd_float3(0, 0, -1))
        let distanceToTarget = simd_length(shipPosition - missilePosition)
        let maxSpeed: Float = 10000.0
        let speedSmoothFactor: Float = 1
        let acceleration: Float = 20
        ApacheHelicopter.speed = min(ApacheHelicopter.speed + acceleration * deltaTime * speedSmoothFactor, maxSpeed)
        let rotationStartDistance: Float = 3000
        let rotationSmoothFactor: Float = 1000
        if distanceToTarget < rotationStartDistance {
            let targetRotation = simd_quaternion(currentDirection, targetDirection)
            let smoothRotation = simd_slerp(missile.node.simdOrientation, targetRotation, rotationSmoothFactor)
            missile.node.simdOrientation = smoothRotation
            missile.particle?.orientationDirection = SCNVector3(-smoothRotation.axis.x, -smoothRotation.axis.y, -smoothRotation.axis.z)
        }
        let forwardDirection = missile.node.simdOrientation.act(simd_float3(0, 0, -1))
        let scnForwardDirection = SCNVector3(forwardDirection.x, forwardDirection.y, forwardDirection.z)
        let impulse = scnForwardDirection * speed * deltaTime * speedSmoothFactor
        missile.node.physicsBody?.applyForce(impulse, asImpulse: true)
        return nextTime
    }
    
    func normalize(vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        return length == 0 ? vector : SCNVector3(vector.x / length, vector.y / length, vector.z / length)
    }
    
    func shootUpperGun() {
        let bullet = SCNNode(geometry: SCNSphere(radius: 0.002)) // Temporarily increase size to make sure it's visible
        bullet.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        print("Gun position: \(upperGun.presentation.worldPosition)")
        bullet.position = SCNVector3(upperGun.presentation.worldPosition.x + 0.009, upperGun.presentation.worldPosition.y + 0.07, upperGun.presentation.worldPosition.z + 0.3)
        let physicsShape = SCNPhysicsShape(geometry: bullet.geometry!, options: nil)
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: physicsShape)
        physicsBody.isAffectedByGravity = false
        bullet.physicsBody = physicsBody
        let forwardDirection = SCNVector3(
            -helicopterNode.presentation.transform.m31,  // x-component of the z-axis
             -helicopterNode.presentation.transform.m32,  // y-component of the z-axis
             -helicopterNode.presentation.transform.m33   // z-component of the z-axis
        )
        if forwardDirection.length() > 0.01 {
            let impulse = forwardDirection * 200  // Adjust force if needed
            bullet.physicsBody?.applyForce(impulse, asImpulse: true)
        } else {
            print("Warning: Forward direction is too small, helicopter rotation might be incorrect.")
        }
        self.helicopterNode.getRootNode().addChildNode(bullet)
        let impulse = forwardDirection * 500
        bullet.physicsBody?.applyForce(impulse, asImpulse: true)
        print("Bullet position after force application: \(bullet.position)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            bullet.removeFromParentNode()
        }
    }
    
}
