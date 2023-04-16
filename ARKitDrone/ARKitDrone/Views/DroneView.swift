//
//  DroneView.swift
//  ARKitDrone
//
//  Created by Christopher Webb-Orenstein on 10/7/17.
//  Copyright © 2017 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class DroneSceneView: ARSCNView {
    
    private var helicopter = ApacheHelicopter()
    
    func setup(scene: SCNScene) {
        helicopter.setup(with: scene)
    }
}

// MARK: - HelicopterCapable

extension DroneSceneView: HelicopterCapable  {
    
    /// Void function that rotates the helicopter based
    /// from *float* value passed
    ///
    /// - Parameters:
    ///     - value: The *value* parameter determines the movement rotation
    ///              of the drone
    ///
    ///
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
    
    func toggleArmMissile() {
        helicopter.toggleArmMissile()
    }
    
    func positionHUD() {
        helicopter.positionHUD()
    }
    
    func missilesArmed() -> Bool {
        return helicopter.missilesAreArmed()
    }
}
