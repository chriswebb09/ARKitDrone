//
//  GameViewController+SCNPhysicsContactDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nameA = contact.nodeA.name ?? ""
        let nameB = contact.nodeB.name ?? ""
        
        let conditionOne = (nameA.contains("Missile") && !nameB.contains("Missile"))
        let conditionTwo = (nameB.contains("Missile") && !nameA.contains("Missile"))
        
        if (game.valueReached && (conditionOne || conditionTwo)) {
            
            let conditionalShipNode: SCNNode! = conditionOne ? contact.nodeB : contact.nodeA
            let conditionalMissileNode: SCNNode! = conditionOne ? contact.nodeA : contact.nodeB
            
            let tempMissile = Missile.getMissile(from: conditionalMissileNode)!
            
            let canUpdateScore = tempMissile.hit == false
            
            tempMissile.hit = true
            
            if canUpdateScore {
                DispatchQueue.main.async {
                    //                    self.game.playerScore = -(self.sceneView.missiles.filter { !$0.hit }.count - 8)
                    self.game.playerScore += 1
                    ApacheHelicopter.speed = 0
                    self.game.updateScoreText()
                    self.destoryedText.fadeTransition(0.001)
                    self.scoreText.fadeTransition(0.001)
                    self.updateGameStateText()
                }
            }
            
            DispatchQueue.main.async {
                Ship.removeShip(conditionalShipNode: conditionalShipNode)
                self.sceneView.positionHUD()
                self.sceneView.helicopter.hud.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.18))
            }
            
            tempMissile.particle?.birthRate = 0
            tempMissile.node.removeAll()
            
            let flashNode = SCNNode.addFlash(contactPoint: contact.contactPoint)
            sceneView.scene.rootNode.addChildNode(flashNode)
            SCNNode.runAndFadeExplosion(flashNode: flashNode)
            sceneView.addExplosion(contactPoint: contact.contactPoint)
            
            DispatchQueue.main.async {
                self.game.scoreUpdated = false
                self.armMissilesButton.isEnabled = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                //                self.game.playerScore = -(self.sceneView.missiles.count - 8)
                self.resetDestroyedText()
            }
        }
    }
    
    func updateGameStateText() {
        destoryedText.text = game.destoryedTextString
        scoreText.text = game.scoreTextString
    }
    
    func resetDestroyedText() {
        game.destoryedTextString = ""
        destoryedText.text = game.destoryedTextString
        destoryedText.fadeTransition(0.001)
    }
}

