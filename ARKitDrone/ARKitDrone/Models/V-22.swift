//
//  Helicopter.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

class Osprey: NSObject {
    
    struct LocalConstants {
        //static let parentModelName = "grpApache"
        static let bodyName = "Body"
        static let frontRotorName = "FrontRotor"
        static let tailRotorName = "TailRotor"
        static let missile1 = "Missile1"
        static let audioFileName = "audio.m4a"
        static let activeEmitterRate: CGFloat = 1000
    }
    
    var helicopterNode: SCNNode!
    var engineNode: SCNNode!
    var parentModelNode: SCNNode!
    var missile: SCNNode!
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var particle: SCNParticleSystem!
    
    
    
    func setup(with scene: SCNScene) {
        
        let tempScene = SCNScene.nodeWithModelName("art.scnassets/osprey.scn")
       
       
        
        let tempsc = SCNScene(named: "art.scnassets/osprey.scn")!
        
       // make3DModel(scene: tempsc, fileName: "osprey")
        // parentModelNode = tempScene.childNode(withName: LocalConstants.parentModelName, recursively: true)
        helicopterNode = tempScene.childNode(withName: LocalConstants.bodyName, recursively: true)
        engineNode = helicopterNode.childNode(withName: "Engine", recursively: true)
        rotor = engineNode.childNode(withName: "Blade", recursively: true)
        helicopterNode.scale = SCNVector3(0.0009, 0.0009, 0.0009)
        //rotor = helicopterNode?.childNode(withName: LocalConstants.frontRotorName, recursively: true)
        //rotor2 = helicopterNode?.childNode(withName: LocalConstants.tailRotorName, recursively: true)
        // missile = helicopterNode?.childNode(withName: LocalConstants.missile1, recursively: false)
        // parentModelNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, -20)
        //        let first =  missile.childNodes.first!
        //        particle = first.particleSystems![0]
        //        particle.birthRate = 0
        spinBlades()
        scene.rootNode.addChildNode(tempScene)
    }
    
    func spinBlades() {
        let rotate = SCNAction.rotateBy(x: 0, y: 10, z: 0, duration: 0.5)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        rotor.runAction(moveLoop)
        //        let rotate2 = SCNAction.rotateBy(x: 0, y: 0, z: 20, duration: 0.5)
        //        let moveSequence2 = SCNAction.sequence([rotate2])
        //        let moveLoop2 = SCNAction.repeatForever(moveSequence2)
        //        rotor.runAction(moveLoop2)
        //        let source = SCNAudioSource(fileNamed: LocalConstants.audioFileName)
        //        source?.volume += 50
        //        let action = SCNAction.playAudio(source!, waitForCompletion: true)
        //        let action2 = SCNAction.repeatForever(action)
        //        helicopterNode.runAction(action2)
    }
    
    func rotate(value: Float) {
        SCNTransaction.begin()
        let locationRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0))
        helicopterNode.localRotate(by: locationRotation)
        SCNTransaction.commit()
    }
    
//    func make3DModel(scene: SCNScene, fileName: String) -> URL? {
//        let fileManager = FileManager.default
//        //let currentPath = fileManager.file
//        let sceneURL = URL(fileURLWithPath: "file:///art.scnassets/" + fileName + ".usdz")
//        let options: [String: Any] = [SCNSceneExportDestinationURL: URL(fileURLWithPath: currentPath, isDirectory: true)]
//        if scene.write(to: sceneURL, options: options, delegate: self, progressHandler: {(progress, error, stop) in
//            if let error = error {
//                NSLog("ShareScene \(String(describing: error))")
//            }
//        }) != true {
//            NSLog("ShareScene Unable to write scene to \(sceneURL)")
//            return nil
//        }
//        return sceneURL
//    }
//
    
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
            let localRotation = SCNQuaternion.getQuaternion(from: SCNQuaternion.angleConversion(x: -0.001 * Float(Double.pi), y:0, z: 0 , w: 0))
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

extension Osprey: SCNSceneExportDelegate {
    
}