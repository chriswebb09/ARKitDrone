//
//  DroneView.swift
//  ARKitDrone
//
//  Created by Christopher Webb-Orenstein on 10/7/17.
//  Copyright © 2017 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import SceneKit

class DroneSceneView: ARSCNView {
    
    var helicopterNode: SCNNode!
    var parentModelNode: SCNNode!
    var missile: SCNNode!
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var particle: SCNParticleSystem!

    func setupDrone() {
        scene = SCNScene(named: "art.scnassets/Apache.scn")!
        parentModelNode = scene.rootNode.childNode(withName: "grpApache", recursively: true)
        helicopterNode = parentModelNode?.childNode(withName: "Body", recursively: true)
        rotor = helicopterNode?.childNode(withName: "FrontRotor", recursively: true)
        rotor2 = helicopterNode?.childNode(withName: "TailRotor", recursively: true)
        missile = helicopterNode?.childNode(withName: "Missile1", recursively: false)
        parentModelNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, -20)
        let first =  missile.childNodes.first!
        particle = first.particleSystems![0]
        particle.birthRate = 0
        spinBlades()
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
        
        let source = SCNAudioSource(fileNamed: "audio.m4a")
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
        let (x, y, z, w) = angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0)
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
        let (x, y, z, w) = angleConversion(x: 0.001 * Float(Double.pi), y:0, z: 0 , w: 0)
        helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        SCNTransaction.completionBlock = { [self] in
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.25
            let (x, y, z, w) = angleConversion(x: -0.001 * Float(Double.pi), y:0, z: 0 , w: 0)
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
            let (x, y, z, w) = angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0)
            helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        } else {
            let (x, y, z, w) = angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0)
            helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        }
        SCNTransaction.completionBlock = { [self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [self] in
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.25
                print(value)
                if abs(value) != value {
                    let (x, y, z, w) = angleConversion(x: 0, y: 0.002 * Float(Double.pi), z: 0 , w: 0)
                    helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
                } else {
                    let (x, y, z, w) = angleConversion(x: 0, y: -0.002 * Float(Double.pi), z: 0 , w: 0)
                    helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
                }
                
                SCNTransaction.commit()
            })
        }
        SCNTransaction.commit()
    }
    
    // https://developer.apple.com/forums/thread/651614?answerId=616792022#616792022
    
    func angleConversion(x: Float, y: Float, z: Float, w: Float) -> (Float, Float, Float, Float) {
        let c1 = cos( x / 2 )
        let c2 = cos( y / 2 )
        let c3 = cos( z / 2 )
        let s1 = sin( x / 2 )
        let s2 = sin( y / 2 )
        let s3 = sin( z / 2 )
        let xF = s1 * c2 * c3 + c1 * s2 * s3
        let yF = c1 * s2 * c3 - s1 * c2 * s3
        let zF = c1 * c2 * s3 + s1 * s2 * c3
        let wF = c1 * c2 * c3 - s1 * s2 * s3
        return (xF, yF, zF, wF)
    }
    
    
}

func nodeWithModelName(_ modelName: String) -> SCNNode {
    return SCNScene(named: modelName)!.rootNode.clone()
}
