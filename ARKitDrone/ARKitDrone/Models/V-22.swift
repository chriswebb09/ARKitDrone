//
//  Helicopter.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

class Osprey {
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let bodyName = "Body"
        static let engineName = "Engine"
        static let frontRotorName = "FrontRotor"
        static let tailRotorName = "TailRotor"
        static let missile1 = "Missile1"
        static let blade = "Blade"
        static let audioFileName = "audio.m4a"
        static let activeEmitterRate: CGFloat = 1000
    }
    
    private var helicopterNode: SCNNode!
    private var engineNode: SCNNode!
    private var parentModelNode: SCNNode!
    private var missile: SCNNode!
    private var rotor: SCNNode!
    private var rotor2: SCNNode!
    private var particle: SCNParticleSystem!
    
    func setup(with scene: SCNScene) {
        let tempScene = SCNScene.nodeWithModelName("art.scnassets/osprey.dae")
        helicopterNode = tempScene.childNode(withName: LocalConstants.bodyName, recursively: true)
        engineNode = helicopterNode.childNode(withName: LocalConstants.engineName, recursively: true)
        rotor = engineNode.childNode(withName: LocalConstants.blade, recursively: true)
        helicopterNode.scale = SCNVector3(0.0009, 0.0009, 0.0009)
        spinBlades()
        scene.rootNode.addChildNode(tempScene)
    }
    
    private func spinBlades() {
        let rotate = SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 0.5)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        rotor.runAction(moveLoop)
    }
    
    func rotate(value: Float) {
        SCNTransaction.begin()
        let locationRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0))
        helicopterNode.localRotate(by: locationRotation)
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y: value, z: 0))
        SCNTransaction.commit()
    }
    
    func shootMissile() {
        particle.birthRate = LocalConstants.activeEmitterRate
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        missile.localTranslate(by: SCNVector3(x: 0, y: 4000, z: 0))
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z + value)
        helicopterNode.localRotate(by: SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0.001 * Float(Double.pi), y:0, z: 0 , w: 0)))
        SCNTransaction.completionBlock = { [self] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
            let angleConversion = SCNQuaternion.angleConversion(x: -0.001 * Float(Double.pi), y:0, z: 0 , w: 0)
            let localRotation = SCNQuaternion.getQuaternion(from: angleConversion)
            helicopterNode.localRotate(by: localRotation)
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
    
    func moveSides(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.localTranslate(by: SCNVector3(x: value, y: 0, z: 0))
        if abs(value) != value {
            let localRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0))
            helicopterNode.localRotate(by: localRotation)
        } else {
            let localRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0))
            helicopterNode.localRotate(by: localRotation)
        }
        SCNTransaction.completionBlock = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [self] in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                if abs(value) != value {
                    let localRotation = SCNQuaternion.getQuaternion(from:SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0))
                    helicopterNode.localRotate(by: localRotation)
                } else {
                    let localRotation = SCNQuaternion.getQuaternion(from:SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0))
                    helicopterNode.localRotate(by: localRotation)
                }
                SCNTransaction.commit()
            })
        }
        SCNTransaction.commit()
    }
}
