//
//  ShipManager.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

class ShipManager {
    var game: Game
    var sceneView: GameSceneView
    
    init(game: Game, sceneView: GameSceneView) {
        self.game = game
        self.sceneView = sceneView
    }
    
    
    func setupShips() {
        let shipScene = SCNScene(named: GameSceneView.LocalConstants.f35Scene)!
        for i in 1...8 {
            let shipNode = shipScene.rootNode.childNode(withName: GameSceneView.LocalConstants.f35Node, recursively: true)!.clone()
            shipNode.name = "F_35B \(i)"
            let ship = Ship(newNode: shipNode)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                sceneView.scene.rootNode.addChildNode(ship.node)
                sceneView.ships.append(ship)
                let randomOffset = SCNVector3(
                    x: Float.random(in: -20.0...20.0),
                    y: Float.random(in: -10.0...10.0),
                    z: Float.random(in: -20.0...40.0)
                )
                ship.node.position = SCNVector3(x:randomOffset.x , y: randomOffset.y, z: randomOffset.z)
                ship.node.scale = SCNVector3(x: 0.005, y: 0.005, z: 0.005)
                if i == 1 {
                    sceneView.targetIndex = 0
                    DispatchQueue.main.async {
                        let square = TargetNode()
                        ship.square = square
                        self.sceneView.scene.rootNode.addChildNode(square)
                        ship.targetAdded = true
                    }
                }
            }
        }
    }
    
    func addTargetToShip() {
        if sceneView.ships.count > sceneView.targetIndex {
            sceneView.targetIndex += 1
            if sceneView.targetIndex < sceneView.ships.count {
                if !sceneView.ships[sceneView.targetIndex].isDestroyed && !sceneView.ships[sceneView.targetIndex].targetAdded {
                    DispatchQueue.main.async {
                        guard self.sceneView.targetIndex < self.sceneView.ships.count else { return }
                        let square = TargetNode()
                        self.sceneView.ships[self.sceneView.targetIndex].square = square
                        self.sceneView.scene.rootNode.addChildNode(square)
                        self.sceneView.ships[self.sceneView.targetIndex].targetAdded = true
                    }
                }
            }
        }
    }
    
    func addExplosion(contactPoint: SCNVector3) {
        let explosion = SCNParticleSystem.createExplosion()
        let explosionNode = SCNNode()
        explosionNode.position = contactPoint
        explosionNode.addParticleSystem(explosion)
        sceneView.scene.rootNode.addChildNode(explosionNode)
        explosionNode.runAction(SCNAction.sequence([
            SCNAction.wait(duration: 0.25),
            SCNAction.removeFromParentNode()
        ]))
    }
    
    func moveShips(placed: Bool) {
        var percievedCenter = SCNVector3Zero
        var percievedVelocity = SCNVector3Zero
        
        for otherShip in sceneView.ships {
            percievedCenter = percievedCenter + otherShip.node.position
            percievedVelocity = percievedVelocity + (otherShip.velocity)
        }
        
        sceneView.ships.forEach {
            
            $0.updateShipPosition(
                percievedCenter: percievedCenter,
                percievedVelocity: percievedVelocity,
                otherShips: sceneView.ships,
                obstacles: [sceneView.helicopterNode]
            )
        }
        
        if placed {
            
            _  = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { [weak self] timer in
                guard let self = self else { return }
                sceneView.attack = true
                timer.invalidate()
            })
            
            for ship in sceneView.ships {
                if sceneView.attack {
                    ship.attack(target: self.sceneView.helicopterNode)
                    _  = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
                        guard let self = self else { return }
                        sceneView.attack = false
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
}
