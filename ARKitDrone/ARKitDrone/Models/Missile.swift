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
    var num: Int = -1
    
    func setupNode(scnNode: SCNNode?, number: Int) {
        guard let scnNode = scnNode else { return }
        node = scnNode
        self.num = number
        setParticle()
        node.name = "Missile \(num)"
        let physicsBody4 =  SCNPhysicsBody(type: .static, shape: nil)
        node?.physicsBody = physicsBody4
        node?.physicsBody?.categoryBitMask = 7
        node?.physicsBody?.contactTestBitMask = 4
        node?.physicsBody?.collisionBitMask = 4
        
    }
    
    func setParticle() {
        guard let particleNode = node.childNodes.first, let particleSystems = particleNode.particleSystems else {
            return
        }
        particle = particleSystems[0]
        particle?.birthRate = 0
    }
    
    func fire(x: Float, y: Float) {
        print("missile \(num)")
        guard fired == false else { return }
        particle?.birthRate = 4000
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 3
        node.localTranslate(by: SCNVector3(x: x, y: y, z: -100000))
        SCNTransaction.commit()
//        self.fired = true
//        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
//            self.node.removeFromParentNode()
//            self.fired = true
//        }
    }
}
