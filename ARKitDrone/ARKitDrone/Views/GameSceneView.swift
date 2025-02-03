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
        static let tankAssetName = "art.scnassets/m1.scn"
    }
    
    private var droneSceneView: DroneSceneView!
    
    var tankModel: SCNNode!
    var tankNode: SCNNode!
    
    func setup() {
        scene = SCNScene(named: LocalConstants.sceneName)!
        tankModel = SCNScene.nodeWithModelName(LocalConstants.tankAssetName)
        tankNode = tankModel.childNode(withName: "m1tank", recursively: true)
        tankNode.scale = SCNVector3(x: 0.03, y: 0.03, z: 0.03)
        tankNode.physicsBody?.categoryBitMask = 2
        droneSceneView = DroneSceneView(frame: UIScreen.main.bounds)
        droneSceneView.setup(scene: scene)
    }
    
    func positionTank(position: SCNVector3) {
        scene.rootNode.addChildNode(tankNode)
        tankNode.position = position
    }
}

// MARK: - HelicopterCapable

extension GameSceneView: HelicopterCapable {
    func missileLock(target: SCNNode) {
        droneSceneView.missileLock(target: target)
    }
    
    
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
        droneSceneView.missileLock(target: tankNode)
    }
    
    func toggleArmMissiles() {
        droneSceneView.toggleArmMissile()
    }
}
