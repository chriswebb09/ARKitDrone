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
    var fired: Bool = false
    var missileNum = 0
    var particle: SCNParticleSystem!
    
    init(num: Int) {
        self.missileNum = num
    }
    
    func setParticle() {
        guard let particleNode = node.childNodes.first, let particleSystems = particleNode.particleSystems else { return }
        particle = particleSystems[0]
        particle.birthRate = 0
    }
    
    func setupNode(scnNode: SCNNode?) {
        guard let scnNode = scnNode else { return }
        node = scnNode
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 0
    }
    
    func fire() {
        guard fired == false else { return }
        particle.birthRate = 1000
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 4
        self.node.localTranslate(by: SCNVector3(x: 0, y: 6000, z: 0))
        SCNTransaction.commit()
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { timer in
            self.node.removeFromParentNode()
        }
        fired = true
    }
}
