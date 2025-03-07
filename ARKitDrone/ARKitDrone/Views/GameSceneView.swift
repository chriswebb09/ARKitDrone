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
        upperGun = helicopterNode.childNode(withName: GameSceneView.upperGun, recursively: true)!
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
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
    
    func moveShips(placed: Bool) {
        var percievedCenter = SCNVector3Zero
        var percievedVelocity = SCNVector3Zero
        
        for otherShip in ships {
            percievedCenter = percievedCenter + otherShip.node.position
            percievedVelocity = percievedVelocity + (otherShip.velocity)
        }
        
        ships.forEach {
            
            $0.updateShipPosition(
                percievedCenter: percievedCenter,
                percievedVelocity: percievedVelocity,
                otherShips: ships,
                obstacles: [helicopterNode]
            )
        }
        
        if placed {
            
            _  = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] timer in
                guard let self = self else { return }
                attack = true
                timer.invalidate()
            })
            
            for ship in ships {
                if attack {
                    ship.attack(target: self.helicopterNode)
                    _  = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
                        guard let self = self else { return }
                        self.attack = false
                        timer.invalidate()
                    })
                }
                
                
            }
        }
        //        if placed {
        //            ships.forEach {
        //                $0.updateShipPosition(target: helicopterNode.position, otherShips: self.ships)
        //            }
        //        } else {
        //            ships.forEach {
        //                $0.updateShipPosition(percievedCenter: percievedCenter, percievedVelocity: percievedVelocity, otherShips: ships, obstacles: [helicopterNode])
        //            }
        //        }
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
                let randomOffset = SCNVector3(
                    x: Float.random(in: -20.0...20.0),
                    y: Float.random(in: -10.0...10.0),
                    z: Float.random(in: -20.0...40.0)
                )
                ship.node.position = SCNVector3(x:randomOffset.x , y: randomOffset.y, z: randomOffset.z)
                ship.node.scale = SCNVector3(x: 0.005, y: 0.005, z: 0.005)
                if i == 1 {
                    targetIndex = 0
                    DispatchQueue.main.async {
                        let square = TargetNode()
                        ship.square = square
                        self.scene.rootNode.addChildNode(square)
                        ship.targetAdded = true
                    }
                }
            }
        }
    }
    
    func addTargetToShip() {
        if ships.count > targetIndex {
            targetIndex += 1
            if targetIndex < ships.count {
                if !ships[targetIndex].isDestroyed && !ships[targetIndex].targetAdded {
                    DispatchQueue.main.async {
                        guard self.targetIndex < self.ships.count else { return }
                        let square = TargetNode()
                        self.ships[self.targetIndex].square = square
                        self.scene.rootNode.addChildNode(square)
                        self.ships[self.targetIndex].targetAdded = true
                    }
                }
            }
        }
    }
    
    func fire(game: Game) {
        guard !missiles.isEmpty, !game.scoreUpdated else { return }
        guard ships.count > targetIndex else { return }
        guard !ships[targetIndex].isDestroyed else { return }
        let ship = ships[targetIndex]
        //.first(where: { !$0.isDestroyed && !$0.targeted }) else { return }
        ship.targeted = true
        guard let missile = missiles.first(where:{ !$0.fired }) else { return }
        missile.fired = true
        game.valueReached = false
        missile.addCollision()
        missileLock(ship: ship)
        missile.node.look(at: ship.node.position)
        ApacheHelicopter.speed = 0
        let targetPos = ship.node.presentation.simdWorldPosition
        let currentPos = missile.node.presentation.simdWorldPosition
        let direction = simd_normalize(targetPos - currentPos)
        missile.particle?.orientationDirection = SCNVector3(-direction.x, -direction.y, -direction.z)
        missile.particle?.birthRate = 500
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMissilePosition))
        displayLink.preferredFramesPerSecond = 60
        
        Missile.activeMissileTrackers[missile.id] = MissileTrackingInfo(
            missile: missile,
            target: ship,
            startTime: CACurrentMediaTime(),
            displayLink: displayLink,
            lastUpdateTime: CACurrentMediaTime()
        )
        
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func updateMissilePosition(displayLink: CADisplayLink) {
        
        guard let trackingInfo = Missile.activeMissileTrackers.first(where: { $0.value.displayLink === displayLink })?.value else {
            displayLink.invalidate()
            return
        }
        
        let missile = trackingInfo.missile
        
        let ship = trackingInfo.target
        
        if missile.hit {
            displayLink.invalidate()
            Missile.activeMissileTrackers[missile.id] = nil
            return
        }
        
        let deltaTime = displayLink.timestamp - trackingInfo.lastUpdateTime
        let speed: Float = 50
        
        let targetPos = ship.node.presentation.simdWorldPosition
        let currentPos = missile.node.presentation.simdWorldPosition
        let direction = simd_normalize(targetPos - currentPos)
        let movement = direction * speed * Float(deltaTime)
        
        missile.node.simdWorldPosition += movement
        missile.node.look(at: ship.node.presentation.position)
        missile.particle?.orientationDirection = SCNVector3(-direction.x, -direction.y, -direction.z)
        
        var updatedInfo = trackingInfo
        updatedInfo.frameCount += 1
        updatedInfo.lastUpdateTime = displayLink.timestamp
        
        Missile.activeMissileTrackers[missile.id] = updatedInfo
//        game.valueReached = updatedInfo.frameCount > 30
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
