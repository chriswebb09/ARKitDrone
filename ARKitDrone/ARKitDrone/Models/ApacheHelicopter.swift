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
    
    private struct LocalConstants {
        static let sceneName = "art.scnassets/Apache.scn"
        static let parentModelName = "grpApache"
        static let bodyName = "Body"
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
    
    private var missile: Missile = Missile(num: 1)
    private var missile2: Missile = Missile(num: 2)
    private var missile3: Missile = Missile(num: 3)
    private var missile4: Missile = Missile(num: 4)
    private var missile5: Missile = Missile(num: 5)
    private var missile6: Missile = Missile(num: 6)
    private var missile7: Missile = Missile(num: 7)
    private var missile8: Missile = Missile(num: 8)
    
    private var rotor: SCNNode!
    private var rotor2: SCNNode!
    private var hud: SCNNode!
    private var front: SCNNode!
    private var frontIR: SCNNode!
    
    private var missilesArmed: Bool = false
    
    private func spinBlades() {
        let rotate = SCNAction.rotateBy(x: 30, y: 0, z: 0, duration: 0.5)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        rotor2.runAction(moveLoop)
        let rotate2 = SCNAction.rotateBy(x: 0, y: 0, z: 20, duration: 0.5)
        let moveSequence2 = SCNAction.sequence([rotate2])
        let moveLoop2 = SCNAction.repeatForever(moveSequence2)
        rotor.runAction(moveLoop2)
        let source = SCNAudioSource(fileNamed: LocalConstants.audioFileName)
        source?.volume += 50
        let action = SCNAction.playAudio(source!, waitForCompletion: true)
        let action2 = SCNAction.repeatForever(action)
        helicopterNode.runAction(action2)
    }
    
    func setup(with scene: SCNScene) {
        let tempScene = SCNScene.nodeWithModelName(LocalConstants.sceneName)
        hud = tempScene.childNode(withName: LocalConstants.hudNodeName, recursively: false)
        parentModelNode = tempScene.childNode(withName: LocalConstants.parentModelName, recursively: true)
        helicopterNode = parentModelNode?.childNode(withName: LocalConstants.bodyName, recursively: true)
        front = helicopterNode.childNode(withName: LocalConstants.frontIRSteering, recursively: true)
        frontIR = front.childNode(withName: LocalConstants.frontIR, recursively: true)
        rotor = helicopterNode?.childNode(withName: LocalConstants.frontRotorName, recursively: true)
        rotor2 = helicopterNode?.childNode(withName: LocalConstants.tailRotorName, recursively: true)
        missile.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile1, recursively: true))
        missile2.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile2, recursively: true))
        missile3.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile3, recursively: true))
        missile4.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile4, recursively: true))
        missile5.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile5, recursively: true))
        missile6.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile6, recursively: true))
        missile7.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile7, recursively: true))
        missile8.setupNode(scnNode: helicopterNode?.childNode(withName: LocalConstants.missile8, recursively: true))
        parentModelNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, -20)
        hud.position = SCNVector3(x: helicopterNode.position.x + 0.6, y: helicopterNode.position.y, z: helicopterNode.position.z)
        frontIR.pivot = SCNMatrix4MakeTranslation(12.0, 0, 8.0)
        hideEmitter()
        spinBlades()
        scene.rootNode.addChildNode(tempScene)
    }
    
    func positionHUD() {
        hud.scale = SCNVector3(0.4, 0.4, 0.4)
        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: -4)
        let constraint = SCNLookAtConstraint(target: helicopterNode)
        constraint.isGimbalLockEnabled = true
        constraint.influenceFactor = 0.1
        hud.constraints = [constraint]
    }
    
    private func hideEmitter() {
        missile.setParticle()
        missile2.setParticle()
        missile3.setParticle()
        missile4.setParticle()
        missile5.setParticle()
        missile6.setParticle()
        missile7.setParticle()
        missile8.setParticle()
    }
    
    func toggleArmMissile() {
        missilesArmed.toggle()
    }
    
    func missilesAreArmed() -> Bool {
        return missilesArmed
    }
    
    func rotate(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        let localAngleConversion = SCNQuaternion.angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0)
        let locationRotation = SCNQuaternion.getQuaternion(from: localAngleConversion)
        helicopterNode.localRotate(by: locationRotation)
        
        let hudAngleConversion = SCNQuaternion.angleConversion(x: 0, y: -value * Float(Double.pi), z: 0, w: 0)
        let hudRotation = SCNQuaternion.getQuaternion(from: hudAngleConversion)
        hud.rotate(by: hudRotation, aroundTarget: helicopterNode.worldPosition)
        let constraint = SCNLookAtConstraint(target: helicopterNode)
        constraint.isGimbalLockEnabled = true
        constraint.influenceFactor = 0.1
        hud.constraints = [constraint]
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y: value, z: 0))
        hud.localTranslate(by:  SCNVector3(x: 0, y: 0, z: (0.01 * value)))
        SCNTransaction.commit()
        let constraint = SCNLookAtConstraint(target: helicopterNode)
        constraint.isGimbalLockEnabled = true
        constraint.influenceFactor = 0.1
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 3.0
        hud.constraints = [constraint]
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z + value)
        helicopterNode.localRotate(by: SCNQuaternion.getQuaternion(from: LocalConstants.altitudeAngleConversion))
        let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
        hud.position = SCNVector3(pos.x + 0.5, pos.y, pos.z + 10)
        SCNTransaction.completionBlock = { [self] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
            helicopterNode.localRotate(by: SCNQuaternion.getQuaternion(from: LocalConstants.negativeAltitudeAngleConversion))
            let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
            hud.position = SCNVector3(pos.x + 0.5, pos.y, pos.z + 10)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
    
    func moveSides(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.localTranslate(by: SCNVector3(x: value, y: 0, z: 0))
        let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
        hud.position = SCNVector3(pos.x, pos.y, pos.z + 10)
        if abs(value) != value {
            let localRotation = SCNQuaternion.getQuaternion(from: LocalConstants.negativeAngleConversion)
            helicopterNode.localRotate(by: localRotation)
            let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
            hud.position = SCNVector3(pos.x, pos.y, pos.z + 10)
        } else {
            let localRotation = SCNQuaternion.getQuaternion(from: LocalConstants.angleConversion)
            helicopterNode.localRotate(by: localRotation)
            let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
            hud.position = SCNVector3(pos.x, pos.y, pos.z + 10)
        }
        SCNTransaction.completionBlock = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [self] in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                if abs(value) != value {
                    let localRotation = SCNQuaternion.getQuaternion(from: LocalConstants.angleConversion)
                    helicopterNode.localRotate(by: localRotation)
                    let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
                    hud.position = SCNVector3(pos.x, pos.y, pos.z + 10)
                } else {
                    let localRotation = SCNQuaternion.getQuaternion(from: LocalConstants.negativeAngleConversion)
                    helicopterNode.localRotate(by: localRotation)
                    let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
                    hud.position = SCNVector3(pos.x, pos.y, pos.z + 10)
                }
                SCNTransaction.commit()
            })
        }
        SCNTransaction.commit()
    }
    
    private func fire(missile: Missile) {
        missile.fire()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.hideEmitter()
        }
    }
    
    func shootMissile() {
        guard missilesArmed else { return }
        if missile.fired == false {
            fire(missile: missile)
            return
        } else if missile2.fired == false {
            fire(missile: missile2)
            return
        } else if missile3.fired == false {
            fire(missile: missile3)
            return
        } else if missile4.fired == false {
            fire(missile: missile4)
            return
        } else if missile5.fired == false {
            fire(missile: missile5)
            return
        } else if missile6.fired == false {
            fire(missile: missile6)
            return
        } else if missile7.fired == false {
            fire(missile: missile7)
            return
        } else if missile8.fired == false {
            fire(missile: missile8)
            return
        }
    }
}
