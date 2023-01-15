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
    
    struct LocalConstants {
        static let parentModelName = "grpApache"
        static let bodyName = "Body"
        static let frontRotorName = "FrontRotor"
        static let tailRotorName = "TailRotor"
        static let missile1 = "Missile1"
        static let audioFileName = "audio.m4a"
        static let activeEmitterRate: CGFloat = 1000
    }
    
    var helicopterNode: SCNNode!
    var parentModelNode: SCNNode!
    var missile: SCNNode!
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var hud: SCNNode!
    var front: SCNNode!
    var frontIR: SCNNode!
    var particle: SCNParticleSystem!
    
    func setup(with scene: SCNScene) {
        let tempScene = SCNScene.nodeWithModelName("art.scnassets/Apache.scn")
        hud = tempScene.childNode(withName: "hud", recursively: false)
        parentModelNode = tempScene.childNode(withName: LocalConstants.parentModelName, recursively: true)
        helicopterNode = parentModelNode?.childNode(withName: LocalConstants.bodyName, recursively: true)
        front = helicopterNode.childNode(withName: "FrontIRSteering", recursively: true)
        frontIR = front.childNode(withName: "FrontIR", recursively: true)
        rotor = helicopterNode?.childNode(withName: LocalConstants.frontRotorName, recursively: true)
        rotor2 = helicopterNode?.childNode(withName: LocalConstants.tailRotorName, recursively: true)
        missile = helicopterNode?.childNode(withName: LocalConstants.missile1, recursively: false)
        parentModelNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, -20)
        hud.position = SCNVector3(x: helicopterNode.position.x + 0.6, y: helicopterNode.position.y, z: helicopterNode.position.z)
        frontIR.pivot = SCNMatrix4MakeTranslation(12.0, 0, 8.0)
        let first =  missile.childNodes.first!
        particle = first.particleSystems![0]
        particle.birthRate = 0
        spinBlades()
        scene.rootNode.addChildNode(tempScene)
    }
    
    func spinBlades() {
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
    
    func rotate(value: Float) {
        print(" rotate(value: Float) {")
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        
        let locationRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0))
        helicopterNode.localRotate(by: locationRotation)
        hud.rotate(by: SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y: -value * Float(Double.pi), z: 0, w: 0)), aroundTarget: helicopterNode.worldPosition)
        let constraint = SCNLookAtConstraint(target: helicopterNode)
        constraint.isGimbalLockEnabled = true
        constraint.influenceFactor = 0.1
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 3.0
        hud.constraints = [constraint]
        SCNTransaction.commit()
        SCNTransaction.commit()
    }
    
//    func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
//        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)
//        
//        // Setup a translation matrix with the desired position
//        var translationMatrix = matrix_identity_float4x4
//        translationMatrix.columns.3.x = position.x
//        translationMatrix.columns.3.y = position.y
//        translationMatrix.columns.3.z = position.z
//        
//        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
//        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
//        node.transform = SCNMatrix4(updatedTransform)
//    }
    
    func moveForward(value: Float) {
        print("moveForward(value: Float) ")
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
    
    func shootMissile() {
        particle.birthRate = LocalConstants.activeEmitterRate
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        missile.localTranslate(by: SCNVector3(x: 0, y: 6000, z: 0))
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z + value)
        helicopterNode.localRotate(by: SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0.001 * Float(Double.pi), y:0, z: 0 , w: 0)))
        let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
        hud.position = SCNVector3(pos.x + 0.5, pos.y, pos.z + 10)
        SCNTransaction.completionBlock = { [self] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
            let localRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: -0.001 * Float(Double.pi), y:0, z: 0 , w: 0))
            helicopterNode.localRotate(by: localRotation)
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
        hud.position = SCNVector3(pos.x + 0.5, pos.y, pos.z + 10)
        if abs(value) != value {
            let localRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0))
            helicopterNode.localRotate(by: localRotation)
            let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
            hud.position = SCNVector3(pos.x + 0.5, pos.y, pos.z + 10)
        } else {
            let localRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0))
            helicopterNode.localRotate(by: localRotation)
            let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
            hud.position = SCNVector3(pos.x + 1, pos.y, pos.z + 10)
        }
        SCNTransaction.completionBlock = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [self] in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                if abs(value) != value {
                    let localRotation = SCNQuaternion.getQuaternion(from:SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0))
                    helicopterNode.localRotate(by: localRotation)
                    let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
                    hud.position = SCNVector3(pos.x + 1, pos.y, pos.z + 10)
                } else {
                    let localRotation = SCNQuaternion.getQuaternion(from:SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0))
                    helicopterNode.localRotate(by: localRotation)
                    let pos = SCNVector3.positionFromTransform(helicopterNode.worldTransform.toSimd())
                    hud.position = SCNVector3(pos.x + 1, pos.y, pos.z + 10)
                }
                SCNTransaction.commit()
            })
        }
        SCNTransaction.commit()
    }
    
    
}
