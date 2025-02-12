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
        let Xmin = -40;
        let Ymin = -40;
        let Zmin = -60;
        let Xmax = 40;
        let Ymax = 40;
        let Zmax = 40;
        if node.position.x < Float(Xmin) {
            rebound.x = 1;
        }
        
        if node.position.x > Float(Xmax) {
            rebound.x = -1;
        }
        
        if node.position.y < Float(Ymin) {
            rebound.y = 1;
        }
        
        if node.position.y > Float(Ymax) {
            rebound.y = -1;
        }
        
        if node.position.z < Float(Zmin) {
            rebound.z = 1;
        }
        
        if node.position.z > Float(Zmax) {
            rebound.z = -1;
        }
        return rebound;
    }
    
    func limitVelocity() {
        let mag = Float(velocity.length())
        let limit = Float(0.9)
        if mag > limit {
            velocity = (velocity/mag) * limit
        }
    }
    
    static func getShip(from node: SCNNode) -> Ship? {
           return shipRegistry[node]
       }
}
