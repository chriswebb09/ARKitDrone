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
    
    var node: SCNNode
    
    var velocity: SCNVector3 = SCNVector3(x: 1, y: 1, z: 1)
    var prevDir: SCNVector3 = SCNVector3(x: 0, y: 1, z: 0)
    
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
        Ship.shipRegistry.removeValue(forKey: node)
    }
    
    func flyCenterOfMass(_ shipCount: Int, _ percievedCenter: SCNVector3) -> SCNVector3 {
        let averagePercievedCenter = percievedCenter / Float(shipCount - 1);
        return (averagePercievedCenter - node.position) / 100
    }
    
    func matchSpeedWithOtherShips(_ shipCount: Int,  _ percievedVelocity: SCNVector3) -> SCNVector3 {
        let averagePercievedVelocity = percievedVelocity / Float(shipCount - 1)
        return (averagePercievedVelocity - velocity)
    }
    
    func boundPositions() -> SCNVector3 {
        
        var rebound = SCNVector3(x: 0, y: 0, z: 0)
        
        let Xmin:Float = -90.0
        let Ymin: Float = -30.0
        let Zmin: Float = -50.0
        let Xmax: Float = 30.0
        let Ymax: Float = 30.0
        let Zmax: Float = 0.0
        
        if node.position.x < Xmin {
            rebound.x = 1
        }
        
        if node.position.x > Xmax {
            rebound.x = -1
        }
        
        if node.position.y < Ymin {
            rebound.y = 1
        }
        
        if node.position.y > Ymax {
            rebound.y = -1
        }
        
        if node.position.z < Zmin {
            rebound.z = 1
        }
        
        if node.position.z > Zmax {
            rebound.z = -1
        }
        
        return rebound
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
    
    
    func smoothForces(forces: SCNVector3, factor: Float) -> SCNVector3 {
        return velocity + forces * factor
    }
    
    func keepASmallDistance(otherShips: [Ship]) -> SCNVector3 {
        var forceAway = SCNVector3(x: 0, y: 0, z: 0)
        for otherShip in otherShips {
            if self.node != otherShip.node {
                let distance = self.node.position.distance(otherShip.node.position)
                if distance < 2 {
                    // Use a stronger force when the ships are closer, but also add damping
                    let strength = (2 - distance) * 5.0  // Repulsion strength
                    forceAway += (self.node.position - otherShip.node.position).normalized() * strength
                }
            }
        }
        return forceAway
    }
    
    func avoidObstacles(obstacles: [SCNNode]) -> SCNVector3 {
        var avoidanceForce = SCNVector3(x: 0, y: 0, z: 0)
        for obstacle in obstacles {
            let distance = self.node.position.distance(obstacle.position)
            if distance < 5.0 {  // Threshold for detecting an obstacle
                avoidanceForce += (self.node.position - obstacle.position).normalized() * 2.0
            }
        }
        return avoidanceForce
    }
    
    func setTargetAboveSelected() {
        if self.targetAdded {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.001
            self.targetNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            self.targetNode.position = SCNVector3(x: self.node.position.x, y: self.node.position.y + 1, z: self.node.position.z - 10)
            SCNTransaction.commit()
        }
    }
    
    func updateShipPosition(percievedCenter: SCNVector3, percievedVelocity: SCNVector3, otherShips: [Ship], obstacles: [SCNNode]) {
        var v1 = flyCenterOfMass(otherShips.count, percievedCenter)
        var v2 = keepASmallDistance(otherShips: otherShips)
        var v3 = matchSpeedWithOtherShips(otherShips.count, percievedVelocity)
        var v4 = boundPositions()
        v1 *= (0.01)
        v2 *= (0.01)
        v3 *= (0.01)
        v4 *= (1.0)
        let forward = SCNVector3(x: 0, y: 0, z: 1)
        let velocityNormal = velocity.normalized()
        let avoidanceForce = avoidObstacles(obstacles: obstacles)
        velocity += avoidanceForce
        velocity = smoothForces(forces: v1 + v2 + v3 + v4, factor: 0.1)
        limitVelocity()
        let nor = forward.cross(velocityNormal)
        let angle = CGFloat(forward.dot(velocityNormal))
        node.rotation = SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: Float(acos(angle)))
        node.position = node.position + (velocity)
        setTargetAboveSelected()
    }
    
}
