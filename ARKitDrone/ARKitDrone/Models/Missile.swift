//
//  Missile.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

class Missile: SCNNode {
    var node: SCNNode!
    var fired: Bool = false
    var missileNum = 0
    var particle: SCNParticleSystem!
    
    init(num: Int) {
        super.init()
        self.missileNum = num
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setParticle() {
        let particleNode =  node.childNodes.first!
        particle = particleNode.particleSystems![0]
        particle.birthRate = 0
    }
}
