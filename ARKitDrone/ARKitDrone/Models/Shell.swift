//
//  Shell.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/31/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import simd

class Shell {
    
    var node: SCNNode
    
    init(_ node: SCNNode) {
        self.node = node
    }
    
    static func createShell() -> Shell {
        let geometry = SCNSphere(radius: 0.005)
        geometry.materials.first?.diffuse.contents = UIColor.red
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody.dynamic()
        return Shell(geometryNode)
    }
    
    func launchProjectile(position: SCNVector3, x: Float, y: Float, z: Float, name: String) {
        let force = SCNVector3(x: Float(x), y: Float(y) , z: z)
        node.name = name
        node.physicsBody?.applyForce(force, at: position, asImpulse: true)
        node.categoryBitMask = GameViewController.ColliderCategory.shell
        node.physicsBody?.contactTestBitMask = GameViewController.ColliderCategory.tank
    }
}

