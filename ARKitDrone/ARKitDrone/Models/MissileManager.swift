//
//  MissileManager.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import  SceneKit

class MissileManager {
    
    var missiles: [Missile] = []
    
    var activeMissileTrackers: [String: MissileTrackingInfo] = [:]
    
    var game: Game
    var sceneView: GameSceneView
    
    init(game: Game, sceneView: GameSceneView) {
        self.game = game
        self.sceneView = sceneView
    }
    
    func fire(game: Game) {
        print("fire")
        guard !sceneView.helicopter.missiles.isEmpty, !game.scoreUpdated else { return }
        guard sceneView.ships.count > sceneView.targetIndex else { return }
        guard !sceneView.ships[sceneView.targetIndex].isDestroyed else { return }
        let ship = sceneView.ships[sceneView.targetIndex]
        ship.targeted = true
        guard let missile = sceneView.helicopter.missiles.first(where: { !$0.fired }) else { return }
        missile.fired = true
        game.valueReached = false
        missile.addCollision()
        //        sceneView.missileLock(ship: ship)
        missile.node.look(at: ship.node.position)
        ApacheHelicopter.speed = 0
        let targetPos = ship.node.presentation.simdWorldPosition
        let currentPos = missile.node.presentation.simdWorldPosition
        let direction = simd_normalize(targetPos - currentPos)
        missile.particle?.orientationDirection = SCNVector3(-direction.x, -direction.y, -direction.z)
        missile.particle?.birthRate = 500
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMissilePosition))
        displayLink.preferredFramesPerSecond = 60
        activeMissileTrackers[missile.id] = MissileTrackingInfo(
            missile: missile,
            target: ship,
            startTime: CACurrentMediaTime(),
            displayLink: displayLink,
            lastUpdateTime: CACurrentMediaTime()
        )
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc private func updateMissilePosition(displayLink: CADisplayLink) {
        print("updateMissilePosition")
        guard let trackingInfo = activeMissileTrackers.first(where: { $0.value.displayLink === displayLink })?.value else {
            displayLink.invalidate()
            return
        }
        let missile = trackingInfo.missile
        let ship = trackingInfo.target
        if missile.hit {
            displayLink.invalidate()
            activeMissileTrackers[missile.id] = nil
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
        activeMissileTrackers[missile.id] = updatedInfo
        if updatedInfo.frameCount > 30 {
            NotificationCenter.default.post(name: .missileCanHit, object: self, userInfo: nil)
        }
    }
    
    func handleContact(_ contact: SCNPhysicsContact) {
        let nameA = contact.nodeA.name ?? ""
        let nameB = contact.nodeB.name ?? ""
        let conditionOne = (nameA.contains("Missile") && !nameB.contains("Missile"))
        let conditionTwo = (nameB.contains("Missile") && !nameA.contains("Missile"))
        if game.valueReached && (conditionOne || conditionTwo) {
            let conditionalShipNode: SCNNode! = conditionOne ? contact.nodeB : contact.nodeA
            let conditionalMissileNode: SCNNode! = conditionOne ? contact.nodeA : contact.nodeB
            guard let tempMissile = Missile.getMissile(from: conditionalMissileNode) else { return }
            let canUpdateScore = !tempMissile.hit
            tempMissile.hit = true
            if canUpdateScore {
                DispatchQueue.main.async {
                    self.game.playerScore += 1
                    ApacheHelicopter.speed = 0
                    self.game.updateScoreText()
                    //                    self.sceneView.positionHUD()
                    NotificationCenter.default.post(name: .updateScore, object: self, userInfo: nil)
                }
            }
            DispatchQueue.main.async {
                let ship = Ship.getShip(from: conditionalShipNode)!
                ship.isDestroyed = true
                ship.removeShip()
                self.sceneView.addExplosion(contactPoint: contact.contactPoint)
                //                self.sceneView.positionHUD()
            }
            tempMissile.particle?.birthRate = 0
            tempMissile.node.removeAll()
        }
    }
}
