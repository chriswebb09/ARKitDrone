//
//  GameSceneView.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import SceneKit

class GameSceneView: ARSCNView {
    
    var droneSceneView: DroneSceneView!
    
    func setup() {
        self.scene = SCNScene(named: "art.scnassets/Game.scn")!
        self.droneSceneView = DroneSceneView(frame: UIScreen.main.bounds)
        self.droneSceneView.setup(scene: scene)
    }
}

extension GameSceneView: HelicopterCapable {
    
    func setup(scene: SCNScene) {
        droneSceneView.setup(scene: scene)
    }
    
    func rotate(value: Float) {
        droneSceneView.rotate(value: value)
    }
    
    func moveForward(value: Float) {
        droneSceneView.moveForward(value: value)
    }
    
    func shootMissile() {
        droneSceneView.shootMissile()
    }
    
    func changeAltitude(value: Float) {
        droneSceneView.changeAltitude(value: -value)
    }
    
    
    func moveSides(value: Float) {
        droneSceneView.moveSides(value: value)
    }
}
