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
    var blade1Node: SCNNode!
    var blade2Node: SCNNode!
    var rotorR: SCNNode!
    var rotorL: SCNNode!
    
    func setupDrone() {
        scene = SCNScene(named: "art.scnassets/Drone.scn")!
        helicopterNode = scene.rootNode.childNode(withName: "helicopter", recursively: false)
        helicopterNode.transform = SCNMatrix4Mult(helicopterNode.transform, SCNMatrix4MakeRotation(Float(Double.pi) / 2, 1, 0, 0))
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z - 1)
        blade1Node = helicopterNode?.childNode(withName: "Rotor_R_2", recursively: true)
        blade2Node = helicopterNode?.childNode(withName: "Rotor_L_2", recursively: true)
        rotorR = blade1Node?.childNode(withName: "Rotor_R", recursively: true)
        rotorL = blade2Node?.childNode(withName: "Rotor_L", recursively: true)
        styleDrone()
        spinBlades()
    }
    
    func styleDrone() {
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor.black
        helicopterNode.geometry?.materials = [bodyMaterial]
        scene.rootNode.geometry?.materials = [bodyMaterial]
        let bladeMaterial = SCNMaterial()
        bladeMaterial.diffuse.contents = UIColor.gray
        let rotorMaterial = SCNMaterial()
        rotorMaterial.diffuse.contents = UIColor.darkGray
        blade1Node.geometry?.materials = [rotorMaterial]
        blade2Node.geometry?.materials = [rotorMaterial]
        rotorR.geometry?.materials = [bladeMaterial]
        rotorL.geometry?.materials = [bladeMaterial]
    }
    
    func spinBlades() {
        let rotate = SCNAction.rotateBy(x: 0, y: 0, z: 200, duration: 0.5)
        let moveSequence = SCNAction.sequence([rotate])
        let moveLoop = SCNAction.repeatForever(moveSequence)
        rotorL.runAction(moveLoop)
        rotorR.runAction(moveLoop)
    }
    
    func moveLeft() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        helicopterNode.position = SCNVector3(helicopterNode.position.x - 0.5, helicopterNode.position.y, helicopterNode.position.z)
        blade2Node.runAction(SCNAction.rotateBy(x: 0.3, y: -0.1, z: 0, duration: 1.5))
        blade1Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.5))
        SCNTransaction.commit()
        blade2Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0.1, z: 0, duration: 0.25))
        blade1Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0, z: 0, duration: 0.25))
    }
    
    func moveRight() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        print(scene.rootNode.childNodes[0].position)
        helicopterNode.position = SCNVector3(helicopterNode.position.x + 0.5, helicopterNode.position.y, helicopterNode.position.z)
        blade2Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.5))
        blade1Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0.1, z: 0, duration: 1.5))
        SCNTransaction.commit()
        blade2Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0, z: 0, duration: 0.25))
        blade1Node.runAction(SCNAction.rotateBy(x: -0.3, y: -0.1, z: 0, duration: 0.25))
    }
    
    func moveForward() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z - 0.5)
        blade2Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.5))
        blade1Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.5))
        SCNTransaction.commit()
        blade2Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0, z: 0, duration: 0.25))
        blade1Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0, z: 0, duration: 0.25))
    }
    
    func reverse() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        helicopterNode.position = SCNVector3(helicopterNode.position.x, helicopterNode.position.y, helicopterNode.position.z + 0.5)
        blade2Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.5))
        blade1Node.runAction(SCNAction.rotateBy(x: 0.3, y: 0, z: 0, duration: 1.5))
        SCNTransaction.commit()
        blade2Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0, z: 0, duration: 0.25))
        blade1Node.runAction(SCNAction.rotateBy(x: -0.3, y: 0, z: 0, duration: 0.25))
    }
    
    func changeAltitude(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        helicopterNode.position = SCNVector3(helicopterNode.position.x, value, helicopterNode.position.z)
        SCNTransaction.commit()
    }
}
