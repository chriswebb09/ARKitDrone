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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        node.physicsBody?.mass = 3
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = 1
        node.physicsBody?.contactTestBitMask = 0
    }
    
    func fire(_ direction: simd_float3) {
        guard fired == false else { return }
        particle.birthRate = 1000
        node.physicsBody?.resetTransform()
        node.physicsBody?.angularVelocityFactor = SCNVector3(0, 0, 0)
        node.simdWorldPosition = SIMD3<Float>(0, 0, 0)
        node.physicsBody?.resetTransform()
        Timer.scheduledTimer(withTimeInterval: 7, repeats: false) { timer in
            self.node.removeFromParentNode()
        }
        fired = true
    }
    
    private func getVectors() -> (SCNVector3, SCNVector3) {
        let direction = node.worldFront
        let position = node.position
        return (direction, position)
    }
}
