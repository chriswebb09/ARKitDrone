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
    
    var missile1: Missile = Missile()
    var missile2: Missile = Missile()
    var missile3: Missile = Missile()
    var missile4: Missile = Missile()
    var missile5: Missile = Missile()
    var missile6: Missile = Missile()
    var missile7: Missile = Missile()
    var missile8: Missile = Missile()
    
    var missiles: [Missile] = []
    
    static let helicopterSceneName = "art.scnassets/Helicopter.scn"
    static let targetScene = "art.scnassets/Target.scn"
    //    static let targetName = "target"
    static let helicopterParentModelName = "Apache"
    static let hudNodeName = "hud"
    static let helicopterBodyName = "Body"
    static let frontRotorName = "FrontRotor"
    static let tailRotorName = "TailRotor"
    static let frontIR = "FrontIR"
    static let frontIRSteering = "FrontIRSteering"
    
    func setup() {
        scene = SCNScene(named: LocalConstants.sceneName)!
        tankModel = SCNScene.nodeWithModelName(LocalConstants.tankAssetName).clone()
        tankNode = tankModel.childNode(withName: "m1tank", recursively: true)
        tankNode.scale = SCNVector3(x: 0.1, y: 0.1, z: 0.1)
        let physicsBody =  SCNPhysicsBody(type: .static, shape: nil)
        tankNode.physicsBody = physicsBody
        tankNode.physicsBody?.categoryBitMask = CollisionTypes.base.rawValue
        tankNode.physicsBody?.contactTestBitMask = CollisionTypes.missile.rawValue
        tankNode.physicsBody?.collisionBitMask = 2
        let tempScene = SCNScene.nodeWithModelName(GameSceneView.helicopterSceneName).clone()
        helicopterModel = tempScene.childNode(withName: GameSceneView.helicopterParentModelName, recursively: true)!
        helicopterModel.scale = SCNVector3(0.001,0.001, 0.001)
        helicopterModel.simdScale = SIMD3<Float>(0.001, 0.001, 0.001)
        helicopterModel.scale = SCNVector3(x: 0.001, y: 0.001, z: 0.001)
        helicopterNode = helicopterModel!.childNode(withName: GameSceneView.helicopterBodyName, recursively: true)
        helicopterNode.simdEulerAngles = SIMD3<Float>(-3.0, 0, 0)
        helicopterNode.simdScale = SIMD3<Float>(0.001, 0.00001, 0.00001)
        helicopterNode.scale = SCNVector3(x: 0.001, y: 0.00001, z: 0.00001)
        hud = helicopterModel!.childNode(withName: GameSceneView.hudNodeName, recursively: false)!
        front = helicopterNode.childNode(withName: GameSceneView.frontIRSteering, recursively: true)
        rotor = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.frontRotorName, recursively: true)
        rotor2 = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.tailRotorName, recursively: true)
        
        wingL = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.wingLName, recursively: true)
        wingR = helicopterNode.childNode(withName: ApacheHelicopter.LocalConstants.wingRName, recursively: true)
        front = helicopterNode.childNode(withName: GameSceneView.frontIRSteering, recursively: true)
        frontIR = front!.childNode(withName:GameSceneView.frontIR, recursively: true)
        
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
    
    func positionTank(position: SCNVector3) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            helicopter.hud = hud
            missiles =  [missile1, missile2, missile3, missile4, missile5, missile6, missile7, missile8]
            helicopter.missile1 = missile1
            helicopter.helicopterNode = helicopterNode
            helicopter.front = front
            helicopter.frontIR = frontIR
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
            helicopterNode.scale = SCNVector3(x: 0.0004, y: 0.0004, z: 0.0004)
            
            //            helicopter.helicopterNode.scale = SCNVector3(x: 0.0001, y: 0.0001, z: 0.0001)
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                scene.rootNode.addChildNode(hud)
                scene.rootNode.addChildNode(tankNode)
                scene.rootNode.addChildNode(helicopterNode)
            }
            
            tankNode.position = position
            helicopterNode.position =  SCNVector3(x:position.x, y:position.y + 0.1, z: position.z - 0.2)
            helicopter.helicopterNode.simdPivot.columns.3.x = -0.5
            
            tankNode.simdPivot.columns.3.x = -0.5
            tankNode.scale = SCNVector3(x: 0.02, y: 0.02, z: 0.02)
            
            helicopter.updateHUD()
            helicopter.hud.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.32))
        }
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
    
    func moveShips() {
        var percievedCenter = SCNVector3Zero
        var percievedVelocity = SCNVector3Zero
        for otherShip in ships {
            percievedCenter = percievedCenter + otherShip.node.position
            percievedVelocity = percievedVelocity + (otherShip.velocity)
        }
        ships.forEach {
            $0.updateShipPosition(percievedCenter: percievedCenter, percievedVelocity: percievedVelocity, otherShips: ships, obstacles: [helicopterNode])
        }
    }
    
    func setupShips() {
        let shipScene = SCNScene(named: LocalConstants.f35Scene)!
        for i in 1...8 {
            let shipNode = shipScene.rootNode.childNode(withName: LocalConstants.f35Node, recursively: true)!.clone()
            shipNode.name = "F_35B \(i)"
            let ship = Ship(newNode: shipNode)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                scene.rootNode.addChildNode(ship.node)
                ships.append(ship)
                //                let randomX = Float(Int(arc4random_uniform(10)) - 5)
                //                let randomY = Float(Int(arc4random_uniform(10)) - 5)
                let randomOffset = SCNVector3(
                    x: Float.random(in: -20.0...20.0),
                    y: Float.random(in: -10.0...10.0),
                    z: Float.random(in: -20.0...20.0)
                )
                ship.node.position = SCNVector3(x:randomOffset.x , y: randomOffset.y, z: randomOffset.z)
                ship.node.scale = SCNVector3(x: 0.0015, y: 0.0015, z: 0.0015)
            }
        }
    }
    
}

// MARK: - HelicopterCapable

extension GameSceneView: HelicopterCapable {
    
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
