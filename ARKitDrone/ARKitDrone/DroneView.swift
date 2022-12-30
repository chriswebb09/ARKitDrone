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
    var modelNode: SCNNode!
    var parentModelNode: SCNNode!
    var geom: SCNNode!
    var helicopterNode2: SCNNode!
    // var blade1Node: SCNNode!
    //var blade2Node: SCNNode!
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var rotorTurn: SCNNode!
    var pale1: SCNNode!
    var pale2: SCNNode!
    //  var rotorL: SCNNode!
    
    func setupDrone() {
        scene = SCNScene(named: "art.scnassets/Helicopter.scn")!
        parentModelNode = scene.rootNode.childNode(withName: "Helicopter", recursively: false)
        geom = parentModelNode?.childNode(withName: "Geom", recursively: true)
        helicopterNode2 = geom?.childNode(withName: "Helicopter", recursively: true)
        modelNode = geom?.childNode(withName: "Heli10", recursively: true)
        helicopterNode = modelNode?.childNode(withName: "Model", recursively: true)
        rotor = helicopterNode?.childNode(withName: "Rotor", recursively: true)
        rotor2 = helicopterNode?.childNode(withName: "Rotor2", recursively: true)
        pale2 = rotor2?.childNode(withName: "Pale2", recursively: true)
        rotorTurn = rotor?.childNode(withName: "RotorTurn", recursively: true)
        pale1 = rotorTurn?.childNode(withName: "Pale1", recursively: true)
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, 20)
        spinBlades()
    }
    
    func spinBlades() {
        let rotate = SCNAction.rotateBy(x: 0, y: 15, z: 0, duration: 0.5)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        pale1.runAction(moveLoop)
        let rotate2 = SCNAction.rotateBy(x: 15, y: 0, z: 0, duration: 0.5)
        let moveSequence2 = SCNAction.sequence([rotate2])
        let moveLoop2 = SCNAction.repeatForever(moveSequence2)
        pale2.runAction(moveLoop2)
    }
    
    func moveSide(value: Float) {
        if (value > 0.5) || (value < -0.5) {
            print(value)
        }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        var x = helicopterNode.position.x
        var z = helicopterNode.position.z
        let len = (x*x + z*z).squareRoot()
        x = x / len
        z = z / len
        var theta = acos(x * -0.487 + z * 0.873)
        theta = 2.0 * Float.pi - theta
        let angle = (Float.pi + theta) * -(Float.pi / 8)
        let s = sin(angle)
        let c = cos(angle)
        helicopterNode.rotate(by: SCNQuaternion(x: 0, y: Float(s), z: 0, w: Float(c)), aroundTarget: scene.rootNode.position)
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z - value)
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        helicopterNode.position = SCNVector3(helicopterNode.position.x, value, helicopterNode.position.z)
        SCNTransaction.commit()
    }
}
