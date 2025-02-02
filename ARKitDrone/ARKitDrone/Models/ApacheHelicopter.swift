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

extension SCNVector3 {
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }
}



extension SCNVector3 {
    func rotate(by quaternion: SCNQuaternion) -> SCNVector3 {
        // Convert the vector to a quaternion (w = 0)
        let vectorQuat = SCNQuaternion(self.x, self.y, self.z, 0)
        
        // Conjugate of the quaternion (invert its vector part)
        let conjugateQuat = SCNQuaternion(-quaternion.x, -quaternion.y, -quaternion.z, quaternion.w)
        
        // Apply the rotation: q * v * q^-1
        let resultQuat = quaternionMultiply(quaternionMultiply(quaternion, vectorQuat), conjugateQuat)
        
        // Return the rotated vector (x, y, z)
        return SCNVector3(resultQuat.x, resultQuat.y, resultQuat.z)
    }
    
    private func quaternionMultiply(_ q1: SCNQuaternion, _ q2: SCNQuaternion) -> SCNQuaternion {
        return SCNQuaternion(
            q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y,
            q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x,
            q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w,
            q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z
        )
    }
}

class ApacheHelicopter {
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
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
        static let activeEmitterRate: CGFloat = 1000
        static let angleConversion = SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float.pi, z: 0 , w: 0)
        static let negativeAngleConversion = SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float.pi, z: 0 , w: 0)
        static let altitudeAngleConversion = SCNQuaternion.angleConversion(x: 0.001 * Float.pi, y:0, z: 0 , w: 0)
        static let negativeAltitudeAngleConversion = SCNQuaternion.angleConversion(x: -0.001 * Float.pi, y:0, z: 0 , w: 0)
    }
    
    private var helicopterNode: SCNNode!
    private var parentModelNode: SCNNode!
    var firing:Bool = false
    private var missile1: Missile = Missile()
    private var missile2: Missile = Missile()
    private var missile3: Missile = Missile()
    private var missile4: Missile = Missile()
    private var missile5: Missile = Missile()
    private var missile6: Missile = Missile()
    private var missile7: Missile = Missile()
    private var missile8: Missile = Missile()
    var missiles: [Missile] = []
    private var rotor: SCNNode!
    private var rotor2: SCNNode!
    private var wingL: SCNNode!
    private var wingR: SCNNode!
    private var hud: SCNNode!
    private var front: SCNNode!
    private var frontIR: SCNNode!
    private var missilesArmed: Bool = false
    var missileLockDirection = SCNVector3(0, 0, 1)
    
    private func spinBlades() {
        DispatchQueue.global(qos: .userInteractive).async {
            let rotate = SCNAction.rotateBy(x: 20, y: 0, z: 0, duration: 0.5)
            let moveSequence = SCNAction.sequence([rotate])
            let moveLoop = SCNAction.repeatForever(moveSequence)
            DispatchQueue.main.async {
                self.rotor2.runAction(moveLoop)
            }
        }
        DispatchQueue.global(qos: .userInteractive).async {
            let rotate2 = SCNAction.rotateBy(x: 0, y: 20, z: 0, duration: 0.25)
            let moveSequence2 = SCNAction.sequence([rotate2])
            let moveLoop2 = SCNAction.repeatForever(moveSequence2)
            DispatchQueue.main.async {
                self.rotor.runAction(moveLoop2)
            }
        }
    }
    
    func setup(with scene: SCNScene) {
        let tempScene = SCNScene.nodeWithModelName(LocalConstants.sceneName)
        parentModelNode = tempScene.childNode(withName: LocalConstants.parentModelName, recursively: true)
        hud = parentModelNode?.childNode(withName: LocalConstants.hudNodeName, recursively: false)
        helicopterNode = parentModelNode?.childNode(withName: LocalConstants.bodyName, recursively: true)
        parentModelNode.scale = SCNVector3(0.02, 0.02, 0.02)
        helicopterNode.scale = SCNVector3(0.02, 0.02, 0.02)
        wingL = helicopterNode?.childNode(withName: LocalConstants.wingLName, recursively: true)
        wingR = helicopterNode?.childNode(withName: LocalConstants.wingRName, recursively: true)
        front = helicopterNode.childNode(withName: LocalConstants.frontIRSteering, recursively: true)
        frontIR = front.childNode(withName: LocalConstants.frontIR, recursively: true)
        rotor = helicopterNode?.childNode(withName: LocalConstants.frontRotorName, recursively: true)
        rotor2 = helicopterNode?.childNode(withName: LocalConstants.tailRotorName, recursively: true)
        missile1.setupNode(scnNode: wingR.childNode(withName: LocalConstants.missile1, recursively: false), number: 1)
        missile2.setupNode(scnNode: wingR.childNode(withName: LocalConstants.missile2, recursively: false), number: 2)
        missile3.setupNode(scnNode: wingR.childNode(withName: LocalConstants.missile3, recursively: false), number: 3)
        missile4.setupNode(scnNode: wingR.childNode(withName: LocalConstants.missile4, recursively: false), number: 4)
        missile5.setupNode(scnNode: wingL.childNode(withName: LocalConstants.missile5, recursively: false), number: 5)
        missile6.setupNode(scnNode: wingL.childNode(withName: LocalConstants.missile6, recursively: false), number: 6)
        missile7.setupNode(scnNode: wingL.childNode(withName: LocalConstants.missile7, recursively: false), number: 7)
        missile8.setupNode(scnNode: wingL.childNode(withName: LocalConstants.missile8, recursively: false), number: 8)
        parentModelNode.position = SCNVector3(helicopterNode.position.x,  helicopterNode.position.y, 0)
        hud.position = SCNVector3(x: helicopterNode.position.x,
                                  y: helicopterNode.position.y,
                                  z: helicopterNode.position.z)
        missiles =  [missile1, missile2, missile3, missile4, missile5, missile6, missile7, missile8]
        positionHUD()
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-12))
        spinBlades()
        scene.rootNode.addChildNode(tempScene)
    }
    
    func positionHUD() {
        hud.scale = SCNVector3(1, 1, 1)
        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: helicopterNode.position.z - 10)
    }
    
    func toggleArmMissile() {
        missilesArmed.toggle()
    }
    
    func missilesAreArmed() -> Bool {
        return missilesArmed
    }
    
    func rotate(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        let localAngleConversion = SCNQuaternion.angleConversion(x: 0, y:  -(0.35 * value) * Float(Double.pi), z: 0, w: 0)
        let locationRotation = SCNQuaternion.getQuaternion(from: localAngleConversion)
        helicopterNode.localRotate(by: locationRotation)
        hud.orientation = helicopterNode.orientation
        positionHUD()
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-12))
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y: 0, z: -value))
        hud.orientation = helicopterNode.orientation
        positionHUD()
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-12))
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y:value, z:0))
        hud.orientation = helicopterNode.orientation
        positionHUD()
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-12))
        SCNTransaction.commit()
    }
    
    func moveSides(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: value, y: 0, z: 0))
        hud.orientation = helicopterNode.orientation
        positionHUD()
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-12))
        SCNTransaction.commit()
    }
    
    func lockOn(target: SCNNode) {
        SCNTransaction.begin()

        // Set the scale for the HUD
        hud.scale = SCNVector3(6, 6, 6)
        // Position the HUD right above the target
        hud.position = SCNVector3(x: target.position.x, y: target.position.y, z: target.position.z)

        // Calculate the direction to the target
        let directionToTarget = target.position - hud.position

        // Create a quaternion that will rotate the HUD to face the target
//        let rotation = SCNQuaternion(x: directionToTarget.x, y: directionToTarget.y, z: directionToTarget.z, w: 1)

        // Apply the rotation to the HUD
//        hud.orientation = rotation
        hud.orientation = target.orientation
        
        hud.position = SCNVector3(x: target.position.x - 4, y: target.position.y + 10, z: target.position.z + 2)

//        // Position the HUD right above the target
//        hud.position = SCNVector3(x: target.position.x - 2, y: target.position.y + 20, z: target.position.z + 10)
//
//        // Make the HUD face the target by setting the orientation
//        let directionToTarget = target.position - hud.position
//        let rotation = SCNMatrix4MakeLookAt(hud.position.x, hud.position.y, hud.position.z, target.position.x, target.position.y, target.position.z)
//        hud.orientation = SCNQuaternion(rotation)

        SCNTransaction.commit()
//        SCNTransaction.begin()
//        hud.scale = SCNVector3(6, 6, 6)
//        hud.position = SCNVector3(x:target.position.x - 2, y: target.position.y + 20, z: target.position.z + 10)
//        hud.orientation = target.orientation
//        hud.position = SCNVector3(x:target.position.x - 2, y: target.position.y + 20, z: target.position.z + 10)
//        hud.orientation = target.orientation
//        SCNTransaction.commit()
    }
//        var targetDir = SCNVector3(0, 0, 1) // Vector3.forward equivalent
//        var missileTracking = false
//        
//        let error = target.position - helicopterNode.position
//        
//        let invertedRotation = SCNQuaternion(-helicopterNode.rotation.x, -helicopterNode.rotation.y, -helicopterNode.rotation.z, helicopterNode.rotation.w)
//        
//        let errorDir = error.rotate(by: invertedRotation).normalized()
//        
//        let rotationMatrix = SCNMatrix4MakeRotation(helicopterNode.rotation.w, helicopterNode.rotation.x, helicopterNode.rotation.y, helicopterNode.rotation.z)
//        
//        // Apply the rotation matrix to the missile lock direction
//        let transformedDirection = SCNVector3Make(
//            rotationMatrix.m11 * missileLockDirection.x + rotationMatrix.m12 * missileLockDirection.y + rotationMatrix.m13 * missileLockDirection.z,
//            rotationMatrix.m21 * missileLockDirection.x + rotationMatrix.m22 * missileLockDirection.y + rotationMatrix.m23 * missileLockDirection.z,
//            rotationMatrix.m31 * missileLockDirection.x + rotationMatrix.m32 * missileLockDirection.y + rotationMatrix.m33 * missileLockDirection.z
//        )
//        
//        missileLockDirection = transformedDirection
        
//        var lockSpeed = 30.0
//        var dt = 0.033
//        let lockSpeedInRadians = lockSpeed * dt * .pi / 180 // Convert lockSpeed to radians
//        var angle = SCNQuaternion.angleConversion(x: , y: targetDir.y, z: targetDir.z, w: targetDir.w)
//        missileLockDirection = missileLockDirection.rotate(by: <#T##SCNQuaternion#>)
//        missileLockDirection = missileLockDirection.rotated(towards: targetDir, angle: lockSpeedInRadians)

//    }
    
//    func lockOn(target: SCNNode) {
//        var targetDir = SCNVector3(0, 0, 1) // Vector3.forward equivalent
//        var missileTracking = false
//        
//        let error = target.position - helicopterNode.position
//        
//        
//        let invertedRotation = SCNQuaternion(-helicopterNode.rotation.x, -helicopterNode.rotation.y, -helicopterNode.rotation.z, helicopterNode.rotation.w)
//        
////        let errorDir = error.rotate(by: invertedRotation).normalized()
//        
//        let errorDir = error.rotate(by: invertedRotation).normalized()
//        
//        let rotationMatrix = SCNMatrix4MakeRotation(helicopterNode.rotation.w, helicopterNode.rotation.x, helicopterNode.rotation.y, helicopterNode.rotation.z)
//
//        // Apply the rotation to the missileLockDirection
//        missileLockDirection = missileLockDirection * rotationMatrix
//        
////        missileLockDirection = helicopterNode.rotation * missileLockDirection
//        
////        if error.length() <= lockRange && SCNVector3.angleBetween(SCNVector3(0, 0, 1), errorDir) <= lockAngle {
////               missileTracking = true
////               targetDir = errorDir
////           }
//        
////        let errorDir = helicopterNode.rotation.
//        
//
////        if let target = Target, !target.plane.dead {
////            let error = target.position - rigidBody.position
////            let errorDir = rigidBody.rotation.inverse * error.normalized() // Transform into local space
////            if error.length() <= lockRange && SCNVector3.angleBetween(SCNVector3(0, 0, 1), errorDir) <= lockAngle {
////                missileTracking = true
////                targetDir = errorDir
////            }
////        }
//    }
    
    func shootMissile() {
        guard (!missiles.isEmpty && missilesArmed) && firing == false else { return }
        let missile = missiles.removeFirst()
        firing = true
        guard missile.fired == false else {
            return
        }
        let invertedOrientation = SCNVector4(-hud.orientation.x, -hud.orientation.y, -hud.orientation.z, hud.orientation.w)
        missile.node.orientation = invertedOrientation
        missile.fire(x: missile.node.position.x, y:  missile.node.position.y)
        firing = false
    }
}
