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
    
    struct LocalConstants {
        static let sceneName =  "art.scnassets/Game.scn"
        
        static let f35Scene = "art.scnassets/F-35B_Lightning_II.scn"
        static let f35Node = "F_35B_Lightning_II"
    }
    
    static let tankAssetName = "art.scnassets/m1.scn"
    
    var ships: [Ship] = [Ship]()
    
    var helicopter = ApacheHelicopter()
    var tankModel: SCNNode!
    var tankNode: SCNNode!
    var helicopterNode: SCNNode!
    var helicopterModel: SCNNode!
    var frontIR: SCNNode!
    var hud: SCNNode!
    var wingL: SCNNode!
    var wingR: SCNNode!
    var front: SCNNode!
    var rotor: SCNNode!
    var rotor2: SCNNode!
    var upperGun: SCNNode!
    
//    var missile1: Missile = Missile()
//    var missile2: Missile = Missile()
//    var missile3: Missile = Missile()
//    var missile4: Missile = Missile()
//    var missile5: Missile = Missile()
//    var missile6: Missile = Missile()
//    var missile7: Missile = Missile()
//    var missile8: Missile = Missile()
//    
//    var missiles: [Missile] = []
    
    var targetIndex = 0
    
    var attack: Bool = false
    
    static let helicopterSceneName = "art.scnassets/Helicopter.scn"
    static let targetScene = "art.scnassets/Target.scn"
    static let helicopterParentModelName = "Apache"
    static let hudNodeName = "hud"
    static let helicopterBodyName = "Body"
    static let frontRotorName = "FrontRotor"
    static let tailRotorName = "TailRotor"
    static let frontIR = "FrontIR"
    static let frontIRSteering = "FrontIRSteering"
    static let upperGun = "UpperGun"
    var competitor: ApacheHelicopter!
    
    func setup() {
        scene = SCNScene(named: LocalConstants.sceneName)!
        tankModel = SCNScene.nodeWithModelName(GameSceneView.tankAssetName).clone()
        tankNode = setupTankNode(tankModel: tankModel)
    }
    
    private func setupTankNode(tankModel: SCNNode) -> SCNNode {
        let tankNode = tankModel.childNode(withName: "m1tank", recursively: true)!
        tankNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        let physicsBody =  SCNPhysicsBody(type: .static, shape: nil)
        tankNode.physicsBody = physicsBody
        tankNode.physicsBody?.categoryBitMask = CollisionTypes.base.rawValue
        tankNode.physicsBody?.contactTestBitMask = CollisionTypes.missile.rawValue
        tankNode.physicsBody?.collisionBitMask = 2
        return tankNode
    }
    
    func positionTank(position: SCNVector3) -> ApacheHelicopter {
        var helicopter = ApacheHelicopter()
//        scene = SCNScene(named: LocalConstants.sceneName)!
//        helicopter.setHelicopterProps()
//        helicopterModel = helicopter.setupHelicopterModel()
        //        tankNode = setupTankNode(tankModel: tankModel)
//        helicopterNode = helicopter.setupHelicopterNode(helicopterModel: helicopterModel)
//        helicopter.setupAdditionalHelicopterComponents()
     //   helicopter.setupMissiles()
      //  helicopter.setupAdditionalHelicopterComponents()
        //        tankModel = SCNScene.nodeWithModelName(GameSceneView.tankAssetName).clone()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
//            setHelicopterProps()
            //helicopter.setHelicopterProps()
            helicopter.helicopterNode.scale = SCNVector3(x: 0.0005, y: 0.0005, z: 0.0005)
            scene.rootNode.addChildNode(helicopter.hud)
            //            scene.rootNode.addChildNode(tankNode)
            scene.rootNode.addChildNode(helicopter.helicopterNode)
            //            tankNode.position = position
            helicopter.helicopterNode.position =  SCNVector3(x:position.x, y:position.y + 0.5, z: position.z - 0.2)
            helicopter.helicopterNode.simdPivot.columns.3.x = -0.5
            //            tankNode.simdPivot.columns.3.x = -0.5
            //            tankNode.scale = SCNVector3(x: 0.07, y: 0.07, z: 0.07)
            helicopter.updateHUD()
            helicopter.hud.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.44))
        }
        return helicopter
    }

    func addExplosion(contactPoint: SCNVector3) {
        let explosion = SCNParticleSystem.createExplosion()
        let explosionNode = SCNNode()
        explosionNode.position = contactPoint
        explosionNode.addParticleSystem(explosion)
        scene.rootNode.addChildNode(explosionNode)
        explosionNode.runAction(SCNAction.sequence([
            SCNAction.wait(duration: 0.25),
            SCNAction.removeFromParentNode()
        ]))
    }
}

// MARK: - HelicopterCapable

extension GameSceneView: HelicopterCapable {
    
    func shootUpperGun() {
        helicopter.shootUpperGun()
    }
    
    func missileLock(ship: Ship) {
        helicopter.lockOn(ship: ship)
    }
    
    func positionHUD() {
        helicopter.updateHUD()
        helicopter.hud.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.16))
    }
    
    func missilesArmed() -> Bool {
        return helicopter.missilesAreArmed()
    }
    
    func rotate(value: Float) {
        helicopter.rotate(value: value)
    }
    
    func moveForward(value: Float) {
        helicopter.moveForward(value: value)
    }
    
    func changeAltitude(value: Float) {
        helicopter.changeAltitude(value: -value)
    }
    
    func moveSides(value: Float) {
        helicopter.moveSides(value: value)
    }
    
    func toggleArmMissiles() {
        helicopter.toggleArmMissile()
    }
}
