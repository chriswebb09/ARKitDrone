//
//  Missile.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

class Missile {
    
    var node: SCNNode!
    var particle: SCNParticleSystem?
    var fired: Bool = false

    func setupNode(scnNode: SCNNode?) {
        guard let scnNode = scnNode else { return }
        node = scnNode
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = 4
        node.physicsBody?.collisionBitMask = 5
        setParticle()
    }
    
    func setParticle() {
           guard let particleNode = node.childNodes.first, 
                    let particleSystems = particleNode.particleSystems else {
               return
           }
           particle = particleSystems[0]
           particle?.birthRate = 0
       }
    
    func fire() {
        guard fired == false else { return }
        particle?.birthRate = 4000
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 3
        self.node.localTranslate(by: SCNVector3(x: 0, y: 0, z: -10000))
        SCNTransaction.commit()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { timer in
            self.node.removeFromParentNode()
            self.fired = true
        }
    }
}
