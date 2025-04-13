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
    
    var position: SCNVector3 = SCNVector3Zero
    var firingRange: Float = 20.0
    var moveSpeed: Float = 0.5     // Speed of movement
    var forwardAngleThreshold: Float = 45.0
    var maxRotation: Float = 0
    
    func setup(with scene: SCNScene, transform: SCNMatrix4) {
        let tempScene = SCNScene(named: LocalConstants.sceneName)!
        tankNode = tempScene.rootNode.childNode(withName: LocalConstants.tank, recursively: true)
        tracksNode = tankNode.childNode(withName: LocalConstants.body, recursively: true)
        turretNode = tankNode.childNode(withName: LocalConstants.turret, recursively: true)
        mainGunNode = turretNode.childNode(withName: LocalConstants.maingun, recursively: true)
        tankNode.transform = transform
        tankNode.simdEulerAngles = SIMD3<Float>(-1.7, 0, 0)
        scene.rootNode.addChildNode(tankNode)
    }
}

extension M1AbramsTank {
    
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

    func distanceToTarget(_ target: M1AbramsTank) -> Float {
        let dx = target.tankNode.position.x - self.tankNode.position.x
        let dz = target.tankNode.position.z - self.tankNode.position.z
        return sqrt(dx * dx + dz * dz)
    }
    
    func angleToTarget(_ target: M1AbramsTank) -> Float {
        let dx = target.tankNode.position.x - self.tankNode.position.x
        let dz = target.tankNode.position.z - self.tankNode.position.z
        return atan2(dz, dx) * 180 / .pi
    }
    

    func hasLineOfSight(to target: M1AbramsTank) -> Bool {
        return true
    }
    
    func decideToEngage(against opponent: M1AbramsTank) {
        let distance = distanceToTarget(opponent)
        let angleToOpponent = angleToTarget(opponent)
        if abs(angleToOpponent) <= forwardAngleThreshold {
            print("M1 Abrams Tank: Opponent is in front.")
            if distance <= firingRange && hasLineOfSight(to: opponent) {
                print("M1 Abrams Tank: Engaging opponent. Target within range and clear line of sight.")
                fire()
            } else {
                print("M1 Abrams Tank: Not in range. Moving toward opponent.")
                move(direction: 1.0)
            }
        } else {
            print("M1 Abrams Tank: Opponent is not in front, repositioning.")
            rotate(angle: angleToOpponent)
            move(direction: 1.0)
        }
    }
}
