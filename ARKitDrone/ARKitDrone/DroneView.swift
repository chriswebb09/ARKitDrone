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
        scene = SCNScene(named: "art.scnassets/Apache2.scn")!
        parentModelNode = scene.rootNode.childNode(withName: "grpApache", recursively: true)
       // geom = parentModelNode?.childNode(withName: "Body", recursively: true)
       // helicopterNode2 = geom?.childNode(withName: "Helicopter", recursively: true)
//        modelNode = geom?.childNode(withName: "Heli10", recursively: true)
        helicopterNode = parentModelNode?.childNode(withName: "Body", recursively: true)
        rotor = helicopterNode?.childNode(withName: "FrontRotor", recursively: true)
        rotor2 = helicopterNode?.childNode(withName: "TailRotor", recursively: true)
//        pale2 = rotor2?.childNode(withName: "Pale2", recursively: true)
//        rotorTurn = rotor?.childNode(withName: "RotorTurn", recursively: true)
//        pale1 = rotorTurn?.childNode(withName: "Pale1", recursively: true)
        
        
////        scene = SCNScene(named: "art.scnassets/Helicopter.scn")!
//        parentModelNode = scene.rootNode.childNode(withName: "Helicopter", recursively: false)
//        geom = parentModelNode?.childNode(withName: "Geom", recursively: true)
//        helicopterNode2 = geom?.childNode(withName: "Helicopter", recursively: true)
//        modelNode = geom?.childNode(withName: "Heli10", recursively: true)
//        helicopterNode = modelNode?.childNode(withName: "Model", recursively: true)
//        rotor = helicopterNode?.childNode(withName: "Rotor", recursively: true)
//        rotor2 = helicopterNode?.childNode(withName: "Rotor2", recursively: true)
//        pale2 = rotor2?.childNode(withName: "Pale2", recursively: true)
//        rotorTurn = rotor?.childNode(withName: "RotorTurn", recursively: true)
//        pale1 = rotorTurn?.childNode(withName: "Pale1", recursively: true)
        parentModelNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, -20)
        spinBlades()
    }
    
    func spinBlades() {
        let rotate = SCNAction.rotateBy(x: 30, y: 0, z: 0, duration: 0.5)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        rotor2.runAction(moveLoop)
        //rotor.
        let rotate2 = SCNAction.rotateBy(x: 0, y: 0, z: 20, duration: 0.5)
        let moveSequence2 = SCNAction.sequence([rotate2])
        let moveLoop2 = SCNAction.repeatForever(moveSequence2)
        rotor.runAction(moveLoop2)
    }
    
    func moveSide(value: Float) {
        if (value > 0.5) || (value < -0.5) {
            print(value)
        }
        SCNTransaction.begin()
        
        let (x, y, z, w) = angleConversion(x: 0, y:0, z:  value * Float(Double.pi), w: 0)
        helicopterNode.localRotate(by: SCNQuaternion(x, y, z, w))
        SCNTransaction.commit()
 //       SCNTransaction.begin()
//        SCNTransaction.animationDuration = 0.5
//        var x = helicopterNode.position.x
//        var z = helicopterNode.position.z
//        let len = (x*x + z*z).squareRoot()
//        x = x / len
//        z = z / len
//        var theta = acos(x * -0.487 + z * 0.873)
//        theta = 2.0 * Float.pi - theta
//        let angle = (Float.pi + theta) * -(Float.pi / 8)
//        let s = sin(angle)
//        let c = cos(angle)
//        helicopterNode.rotate(by: SCNQuaternion(x: 0, y: Float(s), z: 0, w: Float(c)), aroundTarget: scene.rootNode.position)
//        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y + value, helicopterNode.position.z)
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z + value)
        SCNTransaction.commit()
    }
    
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
