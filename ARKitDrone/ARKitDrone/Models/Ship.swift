//
//  Ship.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/11/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import QuartzCore

class Ship {
    
    var node: SCNNode;
    var velocity: SCNVector3 = SCNVector3(x: Float(1), y: Float(1), z:Float(1))
    var prevDir: SCNVector3 = SCNVector3(x: Float(0), y: Float(1), z:Float(0))
    private static var shipRegistry: [SCNNode: Ship] = [:]
    var isDestroyed: Bool = false
    var targetNode: SCNNode!
    var targetAdded = false
    var id: String!
    
    init(newNode: SCNNode) {
        self.node = newNode;
        self.id = UUID.init().uuidString
        Ship.shipRegistry[newNode] = self
        let physicsBody =  SCNPhysicsBody(type: .kinematic, shape: nil)
        node.physicsBody = physicsBody
        node.physicsBody!.categoryBitMask = CollisionTypes.missile.rawValue
        node.physicsBody!.contactTestBitMask = CollisionTypes.base.rawValue
        node.physicsBody!.collisionBitMask = 2
    }
    
    deinit {
            Ship.shipRegistry.removeValue(forKey: node) // Clean up when object is destroyed
        }
    
    func flyCenterOfMass(_ shipCount: Int, _ percievedCenter: SCNVector3) -> SCNVector3 {
        let averagePercievedCenter = percievedCenter / Float(shipCount - 1);
        return (averagePercievedCenter - node.position) / 100;
    }
    
    func matchSpeedWithOtherShips(_ shipCount: Int,  _ percievedVelocity: SCNVector3) -> SCNVector3 {
        let averagePercievedVelocity = percievedVelocity / Float(shipCount - 1);
        return (averagePercievedVelocity - velocity)
    }
    
    func boundPositions() -> SCNVector3 {
        var rebound = SCNVector3(x: Float(0), y: Float(0), z:Float(0))
        let Xmin = -20;
        let Ymin = -20;
        let Zmin = -70;
        let Xmax = 20;
        let Ymax = 20;
        let Zmax = 0;
        if node.position.x < Float(Xmin) {
            rebound.x = 1
        }
        
        if node.position.x > Float(Xmax) {
            rebound.x = -1
        }
        
        if node.position.y < Float(Ymin) {
            rebound.y = 1
        }
        
        if node.position.y > Float(Ymax) {
            rebound.y = -1
        }
        
        if node.position.z < Float(Zmin) {
            rebound.z = 1
        }
        
        if node.position.z > Float(Zmax) {
            rebound.z = -1
        }
        return rebound;
    }
    
    func limitVelocity() {
        let mag = Float(velocity.length())
        let limit = Float(0.8)
        if mag > limit {
            velocity = (velocity/mag) * limit
        }
    }
    
    static func getShip(from node: SCNNode) -> Ship? {
           return shipRegistry[node]
       }
}
