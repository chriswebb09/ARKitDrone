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
        static let tankAssetName = "art.scnassets/m1.scn"
        static let f35Scene = "art.scnassets/F-35B_Lightning_II.scn"
        static let f35Node = "F_35B_Lightning_II"
    }
    
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
    
    var missile1: Missile = Missile()
    var missile2: Missile = Missile()
    var missile3: Missile = Missile()
    var missile4: Missile = Missile()
    var missile5: Missile = Missile()
    var missile6: Missile = Missile()
    var missile7: Missile = Missile()
    var missile8: Missile = Missile()
    
    var missiles: [Missile] = []
    
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
    
    func setup() {
        scene = SCNScene(named: LocalConstants.sceneName)!
        setupTankNode()
        setupHelicopterNode()
        setupAdditionalHelicopterComponents()
        setupMissiles()
    }
    
    private func setupAdditionalHelicopterComponents() {
        hud = helicopterModel!.childNode(withName: GameSceneView.hudNodeName, recursively: false)!
        front = helicopterNode.childNode(withName: GameSceneView.frontIRSteering, recursively: true)
        rotor = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.frontRotorName, recursively: true)
        rotor2 = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.tailRotorName, recursively: true)
        wingL = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.wingLName, recursively: true)
        wingR = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.wingRName, recursively: true)
        front = helicopterNode.childNode(withName: GameSceneView.frontIRSteering, recursively: true)
        frontIR = front!.childNode(withName:GameSceneView.frontIR, recursively: true)
        upperGun = helicopterNode.childNode(withName: GameSceneView.upperGun, recursively: true)!
    }
    
    private func setupTankNode() {
        tankModel = SCNScene.nodeWithModelName(LocalConstants.tankAssetName).clone()
        tankNode = tankModel.childNode(withName: "m1tank", recursively: true)
        tankNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        let physicsBody =  SCNPhysicsBody(type: .static, shape: nil)
        tankNode.physicsBody = physicsBody
        tankNode.physicsBody?.categoryBitMask = CollisionTypes.base.rawValue
        tankNode.physicsBody?.contactTestBitMask = CollisionTypes.missile.rawValue
        tankNode.physicsBody?.collisionBitMask = 2
    }
    
    func positionTank(position: SCNVector3) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            setHelicopterProps()
            helicopterNode.scale = SCNVector3(x: 0.0005, y: 0.0005, z: 0.0005)
            scene.rootNode.addChildNode(hud)
            scene.rootNode.addChildNode(tankNode)
            scene.rootNode.addChildNode(helicopterNode)
            tankNode.position = position
            helicopterNode.position =  SCNVector3(x:position.x, y:position.y + 0.5, z: position.z - 0.2)
            helicopter.helicopterNode.simdPivot.columns.3.x = -0.5
            tankNode.simdPivot.columns.3.x = -0.5
            tankNode.scale = SCNVector3(x: 0.07, y: 0.07, z: 0.07)
            helicopter.updateHUD()
            helicopter.hud.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.44))
        }
    }
    
    func setupMissiles() {
        let missile1Node = wingR!.childNode(withName: ApacheHelicopter.LocalConstants.missile1, recursively: false)!
        missile1.setupNode(scnNode: missile1Node, number: 1)
        let missile2Node = wingR?.childNode(withName: ApacheHelicopter.LocalConstants.missile2, recursively: false)!
        missile2.setupNode(scnNode:missile2Node, number: 2)
        missile3.setupNode(scnNode: wingR!.childNode(withName: ApacheHelicopter.LocalConstants.missile3, recursively: false), number: 3)
        missile4.setupNode(scnNode: wingR.childNode(withName: ApacheHelicopter.LocalConstants.missile4, recursively: true), number: 4)
        missile5.setupNode(scnNode: wingL.childNode(withName: ApacheHelicopter.LocalConstants.missile5, recursively: true), number: 5)
        missile6.setupNode(scnNode: wingL.childNode(withName: ApacheHelicopter.LocalConstants.missile6, recursively: true), number: 6)
        missile7.setupNode(scnNode: wingL.childNode(withName: ApacheHelicopter.LocalConstants.missile7, recursively: true), number: 7)
        missile8.setupNode(scnNode: wingL.childNode(withName: ApacheHelicopter.LocalConstants.missile8, recursively: true), number: 8)
    }
    
    func setupHelicopterNode() {
        let tempScene = SCNScene.nodeWithModelName(GameSceneView.helicopterSceneName).clone()
        guard let model = tempScene.childNode(withName: GameSceneView.helicopterParentModelName, recursively: true) else {
            fatalError("Failed to find helicopter parent model: \(GameSceneView.helicopterParentModelName)")
        }
        helicopterModel = model
        let modelScale: Float = 0.001
        helicopterModel.scale = SCNVector3(modelScale, modelScale, modelScale)
        helicopterModel.simdScale = SIMD3<Float>(modelScale, modelScale, modelScale)
        guard let bodyNode = helicopterModel.childNode(withName: GameSceneView.helicopterBodyName, recursively: true) else {
            fatalError("Failed to find helicopter body node: \(GameSceneView.helicopterBodyName)")
        }
        helicopterNode = bodyNode
        helicopterNode.simdEulerAngles = SIMD3<Float>(-3.0, 0, 0)
        let bodyScale = SCNVector3(0.001, 0.00001, 0.00001)
        helicopterNode.scale = bodyScale
        helicopterNode.simdScale = SIMD3<Float>(bodyScale.x, bodyScale.y, bodyScale.z)
    }
    
    func setHelicopterProps() {
        helicopter.hud = hud
        missiles =  [missile1, missile2, missile3, missile4, missile5, missile6, missile7, missile8]
        helicopter.missile1 = missile1
        helicopter.helicopterNode = helicopterNode
        helicopter.front = front
        helicopter.frontIR = frontIR
        helicopter.upperGun = upperGun
        helicopter.missile1 = missile1
        helicopter.missile2 = missile2
        helicopter.missile3 = missile3
        helicopter.missile4 = missile4
        helicopter.missile5 = missile5
        helicopter.missile6 = missile6
        helicopter.missile7 = missile7
        helicopter.missile8 = missile8
        helicopter.missiles = missiles
        helicopter.rotor = rotor
        helicopter.rotor2 = rotor2
        helicopter.setup(with: helicopterNode)
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
