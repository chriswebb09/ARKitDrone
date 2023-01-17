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
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let sceneName =  "art.scnassets/Game.scn"
    }
    
    private var droneSceneView: DroneSceneView!
    
    func setup() {
        scene = SCNScene(named: LocalConstants.sceneName)!
        droneSceneView = DroneSceneView(frame: UIScreen.main.bounds)
        droneSceneView.setup(scene: scene)
    }
}

// MARK: - HelicopterCapable

extension GameSceneView: HelicopterCapable {
    
    func positionHUD() {
        droneSceneView.positionHUD()
    }
    
    func missilesArmed() -> Bool {
        return droneSceneView.missilesArmed()
    }
    
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
    
    func toggleArmMissiles() {
        droneSceneView.toggleArmMissile()
    }
}
