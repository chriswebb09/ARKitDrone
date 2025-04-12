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
    var targetIndex = 0
    
    var attack: Bool = false
    
 
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
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }


            helicopter.helicopterNode.scale = SCNVector3(x: 0.0005, y: 0.0005, z: 0.0005)
            scene.rootNode.addChildNode(helicopter.hud)

            scene.rootNode.addChildNode(helicopter.helicopterNode)
            //            tankNode.position = position
            helicopter.helicopterNode.position =  SCNVector3(x:position.x, y:position.y + 0.5, z: position.z - 0.2)
            helicopter.helicopterNode.simdPivot.columns.3.x = -0.5
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
