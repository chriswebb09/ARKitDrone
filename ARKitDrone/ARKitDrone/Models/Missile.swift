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
    var exhaustNode: SCNNode!
    var hit: Bool = false
    var num: Int = -1
    
    func setupNode(scnNode: SCNNode?, number: Int) {
        guard let scnNode = scnNode else { return }
        node = scnNode
        num = number
        
        node.name = "Missile \(num)"
        let physicsBody2 =  SCNPhysicsBody(type: .kinematic, shape: nil)
        node.physicsBody = physicsBody2
        node.physicsBody?.categoryBitMask = CollisionTypes.base.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.missile.rawValue
        node.physicsBody?.collisionBitMask = 2
        setParticle()
        //        exhaustNode = SCNNode()
        //        exhaustNode.position = node.position
        //        exhaustNode.position = SCNVector3(node.position.x, node.position.y, node.position.z + 1.4) // Adjust to match missile model
        //        node.addChildNode(exhaustNode)
        //        exhaustNode.transform = node.presentation.worldTransform
        //        setParticle()
    }
    
    func setParticle() {
        guard let particleNode = node.childNodes.first, let particleSystems = particleNode.particleSystems else {
            return
        }
        particle = particleSystems[0]
        particle?.birthRate = 0
        if let exhaust = exhaustNode {
            exhaust.addParticleSystem(particle!)
        }
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
