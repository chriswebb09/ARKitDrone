//
//  Helicopter.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import simd

class ApacheHelicopter {
    
    // MARK: - LocalConstants
    
    struct LocalConstants {
        static let sceneName = "art.scnassets/Apache.scn"
        static let parentModelName = "grpApache"
        static let bodyName = "Body"
        static let wingLName = "Wing_L"
        static let wingRName = "Wing_R"
        static let frontRotorName = "FrontRotor"
        static let tailRotorName = "TailRotor"
        static let hudNodeName = "hud"
        static let frontIRSteering = "FrontIRSteering"
        static let missile1 = "Missile1"
        static let missile2 = "Missile2"
        static let missile3 = "Missile3"
        static let missile4 = "Missile4"
        static let missile5 = "Missile5"
        static let missile6 = "Missile6"
        static let missile7 = "Missile7"
        static let missile8 = "Missile8"
        static let frontIR = "FrontIR"
        static let audioFileName = "audio.m4a"
        static let activeEmitterRate: CGFloat = 1000
        static let angleConversion = SCNQuaternion.angleConversion(x: 0, y: 0.002 * Float.pi, z: 0 , w: 0)
        static let negativeAngleConversion = SCNQuaternion.angleConversion(x: 0, y: -0.002 * Float.pi, z: 0 , w: 0)
        static let altitudeAngleConversion = SCNQuaternion.angleConversion(x: 0.001 * Float.pi, y:0, z: 0 , w: 0)
        static let negativeAltitudeAngleConversion = SCNQuaternion.angleConversion(x: -0.001 * Float.pi, y:0, z: 0 , w: 0)
    }
    
    var helicopterNode: SCNNode!
    private var parentModelNode: SCNNode!
    var firing:Bool = false
    var missile1: Missile!
    var currentMissile: Missile!
    var missile2: Missile!
    var missile3: Missile!
    var missile4: Missile = Missile()
    var missile5: Missile = Missile()
    var missile6: Missile = Missile()
    var missile7: Missile = Missile()
    var missile8: Missile = Missile()
    var missiles: [Missile] = []
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var wingL: SCNNode!
    var wingR: SCNNode!
    var hud: SCNNode!
    var front: SCNNode!
    var frontIR: SCNNode!
    var missilesArmed: Bool = false
    var missileLockDirection = SCNVector3(0, 0, 1)
    
    var targetPosition: SCNVector3!
    
    func spinBlades() {
        DispatchQueue.global(qos: .userInteractive).async {
            let rotate = SCNAction.rotateBy(x: 20, y: 0, z: 0, duration: 0.5)
            let moveSequence = SCNAction.sequence([rotate])
            let moveLoop = SCNAction.repeatForever(moveSequence)
            DispatchQueue.main.async {
                self.rotor2.runAction(moveLoop)
            }
        }
        DispatchQueue.global(qos: .userInteractive).async {
            let rotate2 = SCNAction.rotateBy(x: 0, y: 20, z: 0, duration: 0.25)
            let moveSequence2 = SCNAction.sequence([rotate2])
            let moveLoop2 = SCNAction.repeatForever(moveSequence2)
            DispatchQueue.main.async {
                self.rotor.runAction(moveLoop2)
            }
        }
    }
    
    func setup(with scene: SCNScene) {
    }
    
    func setup(with helicopterNode: SCNNode) {
        hud.position = SCNVector3(x: helicopterNode.position.x,
                                  y: helicopterNode.position.y,
                                  z: helicopterNode.position.z)
        missiles =  [missile1, missile2, missile3, missile4, missile5, missile6, missile7, missile8]
        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: helicopterNode.position.z - 3)
        spinBlades()
    }
    
    func toggleArmMissile() {
        missilesArmed.toggle()
    }
    
    func missilesAreArmed() -> Bool {
        return missilesArmed
    }
    
    func rotate(value: Float) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        let localAngleConversion = SCNQuaternion.angleConversion(x: 0, y:  -(0.35 * value) * Float(Double.pi), z: 0, w: 0)
        let locationRotation = SCNQuaternion.getQuaternion(from: localAngleConversion)
        helicopterNode.localRotate(by: locationRotation)
        updateHUD()
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-5))
        SCNTransaction.commit()
    }
    
    func moveForward(value: Float) {
        let val = (value / 50.0)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y: 0, z: -val))
        updateHUD()
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-5))
        SCNTransaction.commit()
    }
    
    func changeAltitude(value: Float) {
        let val = (value / 50.0)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: 0, y:val, z:0))
        updateHUD()
        hud.localTranslate(by: SCNVector3(x: 0, y:0, z:-5))
        SCNTransaction.commit()
    }
    
    private func updateHUD() {
        //        hud.orientation = helicopterNode.orientation
        //        hud.scale = SCNVector3(1, 1, 1)
        //        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: helicopterNode.position.z)
    }
    
    func moveSides(value: Float) {
        let val = (-value / 50.0)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.15
        helicopterNode.localTranslate(by: SCNVector3(x: val, y: 0, z: 0))
        updateHUD()
        //        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-5))
        SCNTransaction.commit()
    }
    
    func lockOn(target: SCNNode) {
        hud.scale = SCNVector3(1.5,1.5, 1.5)
        targetPosition = target.position
        hud.position = SCNVector3(x: helicopterNode.position.x, y: helicopterNode.position.y , z: helicopterNode.position.z)
        hud.orientation = target.orientation
        hud.look(at: target.position)
        let distance = helicopterNode.position.distance(target.position) - 2
        hud.localTranslate(by:  SCNVector3(x: 0, y:0, z:-distance))
    }
    
    func update(missile: Missile, target: SCNNode) {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.001
        missile.node.simdWorldTransform = target.simdWorldTransform
        missile.node.localTranslate(by: SCNVector3(x: 30, y:30, z: -1000))
        SCNTransaction.commit()
    }
    
    func getRootNode(from node: SCNNode) -> SCNNode {
        var currentNode = node
        while let parent = currentNode.parent {
            currentNode = parent
        }
        return currentNode
    }
    
    func shootMissile() {
        guard (!missiles.isEmpty && missilesArmed) && firing == false else { return }
        let missile = missiles.removeFirst()
        currentMissile = missile
        firing = false
    }
    
    func normalize(vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        return length == 0 ? vector : SCNVector3(vector.x / length, vector.y / length, vector.z / length)
    }
}
