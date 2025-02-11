//
//  M1Tank.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/31/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import simd

class M1AbramsTank {
    
    private struct LocalConstants {
        static let sceneName = "art.scnassets/m1.scn"
        static let tank = "m1tank"
        static let turret = "turret"
        static let maingun = "gun"
        static let body = "body"
    }
    
    var tankRotateAngle: Double = 0.0
    
    private var tankNode: SCNNode!
    private var tracksNode: SCNNode!
    private var turretNode: SCNNode!
    private var mainGunNode: SCNNode!
    private var maxUp: Float = -0.133
    private var maxDown: Float = 0.133
    
    var maxRotation: Float = 0
    
    func setup(with scene: SCNScene, transform: SCNMatrix4) {
        let tempScene = SCNScene(named: LocalConstants.sceneName)!
        tankNode = tempScene.rootNode.childNode(withName: LocalConstants.tank, recursively: true)
        tracksNode = tankNode.childNode(withName: LocalConstants.body, recursively: true)
        turretNode = tankNode.childNode(withName: LocalConstants.turret, recursively: true)
        mainGunNode = turretNode.childNode(withName: LocalConstants.maingun, recursively: true)
        tankNode.transform = transform
//        tankNode.simdScale = SIMD3<Float>(repeating: 0.04)
        tankNode.simdEulerAngles = SIMD3<Float>(-1.7, 0, 0)
        scene.rootNode.addChildNode(tankNode)
    }
}

extension M1AbramsTank: Tank {
    
    func place(transform: float4x4) {
        tankNode.transform = SCNMatrix4(transform)
    }
    
    func rotate(angle: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        let localAngleConversion = SCNQuaternion.angleConversion(x: 0, y:0, z:  angle * Float(Double.pi), w: 0)
        let locationRotation = SCNQuaternion.getQuaternion(from: localAngleConversion)
        tankNode.localRotate(by: locationRotation)
        SCNTransaction.commit()
    }
    
    
    func rotateTurret(rotation: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        let localAngleConversion = SCNQuaternion.angleConversion(x: 0, y:0, z:  rotation * Float(Double.pi), w: 0)
        let locationRotation = SCNQuaternion.getQuaternion(from: localAngleConversion)
        turretNode.localRotate(by: locationRotation)
        SCNTransaction.commit()
    }
    
    func moveTurretVertical(value: Float) {
        
    }
    
    func fire() {
        let shell = Shell.createShell()
        tankNode.parent?.addChildNode(shell.node)
        let normalizedBarrelFront = mainGunNode.rotation
        shell.node.simdPosition = mainGunNode.simdWorldPosition //+ normalizedBarrelFront
        launchProjectile(node: shell.node, position: SCNVector3Zero, x: normalizedBarrelFront.x * 0.5, y: normalizedBarrelFront.y * 0.5, z: normalizedBarrelFront.z * 0.5, name: "shell")
    }
    
    
    func launchProjectile(node: SCNNode, position: SCNVector3, x: Float, y: Float, z: Float, name: String) {
        let force = SCNVector3(x: Float(x), y: Float(y) , z: z)
        node.name = name
        node.physicsBody?.applyForce(force, at: position, asImpulse: true)
    }
    
    func move(direction: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.25
        let dir = direction * 0.8
        tankNode.localTranslate(by: SCNVector3(x: 0, y: dir, z: 0))
        SCNTransaction.commit()
    }
}




