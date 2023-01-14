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
    
    var helicopter = Helicopter()
    
    func setup() {
        scene = SCNScene(named: "art.scnassets/Apache.scn")!
        helicopter.setup(with: scene)
    }
    func rotate(value: Float) {
        helicopter.rotate(value: value)
    }
    
    func moveForward(value: Float) {
        helicopter.moveForward(value: value)
    }
    
    func shootMissile() {
        helicopter.shootMissile()
    }
    
    func changeAltitude(value: Float) {
        helicopter.changeAltitude(value: value)
    }
    
    
    func moveSides(value: Float) {
        helicopter.moveSides(value: value)
    }
}

func nodeWithModelName(_ modelName: String) -> SCNNode {
    return SCNScene(named: modelName)!.rootNode.clone()
}
