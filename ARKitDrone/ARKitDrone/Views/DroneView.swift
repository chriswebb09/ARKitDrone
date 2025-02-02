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
    func missileLock(target: SCNNode) {
        helicopter.lockOn(target: target)
    }
    
    
    /// Void function that rotates the helicopter based from *float* value passed
    ///
    /// - Parameters:
    ///     - value: The *value* parameter determines the movement rotation of the drone
    ///
    
    func rotate(value: Float) {
        helicopter.rotate(value: value)
    }
    
    /// Void function that change the position of the helicopter based from *float* value passed
    ///
    /// - Parameters:
    ///     - value: The *value* parameter determines the movement forward and backward of the drone
    ///

    
    func moveForward(value: Float) {
        helicopter.moveForward(value: (value / 30.0))
    }
    
    /// Void function that trigger a misile firing

    func shootMissile() {
        helicopter.shootMissile()
    }
    
    /// Void function that change the altitude of the helicopter based from *float* value passed
    ///
    /// - Parameters:
    ///     - value: The *value* parameter determines the altitude of the drone
    ///
    
    func changeAltitude(value: Float) {
        helicopter.changeAltitude(value: value / 10)
    }
    
    func moveSides(value: Float) {
        helicopter.moveSides(value: value / 10)
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
