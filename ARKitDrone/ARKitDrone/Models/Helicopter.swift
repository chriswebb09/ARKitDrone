//
//  Helicopter.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

class Helicopter {
    
    struct LocalConstants {
        static let parentModelName = "grpApache"
        static let bodyName = "Body"
        static let frontRotorName = "FrontRotor"
        static let tailRotorName = "TailRotor"
        static let missile1 = "Missile1"
        static let audioFileName = "audio.m4a"
    }
    
    var helicopterNode: SCNNode!
    var parentModelNode: SCNNode!
    var missile: SCNNode!
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var particle: SCNParticleSystem!
    
    func setup(with scene: SCNScene) {
        let tempScene = SCNScene.nodeWithModelName("art.scnassets/Apache.scn")
        parentModelNode = tempScene.childNode(withName: LocalConstants.parentModelName, recursively: true)
        helicopterNode = parentModelNode?.childNode(withName: LocalConstants.bodyName, recursively: true)
        rotor = helicopterNode?.childNode(withName: LocalConstants.frontRotorName, recursively: true)
        rotor2 = helicopterNode?.childNode(withName: LocalConstants.tailRotorName, recursively: true)
        missile = helicopterNode?.childNode(withName: LocalConstants.missile1, recursively: false)
        parentModelNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, -20)
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
        if (value > 0.5) || (value < -0.5) {
            print(value)
        }
        SCNTransaction.begin()
        let (x, y, z, w) = SCNQuaternion.angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0)
        helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y: value, z: 0))
        SCNTransaction.commit()
    }
    
    func shootMissile() {
        particle.birthRate = 1000
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1
        missile.localTranslate(by: SCNVector3(x: 0, y: 4000, z: 0))
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z + value)
        let (x, y, z, w) = SCNQuaternion.angleConversion(x: 0.001 * Float(Double.pi), y:0, z: 0 , w: 0)
        helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        SCNTransaction.completionBlock = { [self] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
            let (x, y, z, w) = SCNQuaternion.angleConversion(x: -0.001 * Float(Double.pi), y:0, z: 0 , w: 0)
            helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
    }
    
    
    func moveSides(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.localTranslate(by: SCNVector3(x: value, y: 0, z: 0))
        if abs(value) != value {
            let (x, y, z, w) = SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0)
            helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        } else {
            let (x, y, z, w) = SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0)
            helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        }
        SCNTransaction.completionBlock = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [self] in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                print(value)
                if abs(value) != value {
                    let (x, y, z, w) = SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0)
                    helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
                } else {
                    let (x, y, z, w) = SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0)
                    helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
                }
                
                SCNTransaction.commit()
            })
        }
        SCNTransaction.commit()
    }
}
