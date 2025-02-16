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
    var targeted: Bool = false
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
        
        let Xmin:Float = -50.0
        let Ymin: Float = -50.0
        let Zmin: Float = -70.0
        let Xmax: Float = 50.0
        let Ymax: Float = 50.0
        let Zmax: Float = 30.0
        
        
        if node.position.x < Xmin {
            rebound.x = Float.random(in: 1...2)
        }
        
        if node.position.x > Xmax {
            rebound.x =  Float.random(in: -3.0 ... -1.0)
        }
        
        if node.position.y < Ymin {
            rebound.y =  Float.random(in:1...2)
        }
        
        if node.position.y > Ymax {
            rebound.y = Float.random(in: -3.0 ... -1.0)
        }
        
        if node.position.z < Zmin {
            rebound.z = Float.random(in:1 ... 2)
        }
        
        if node.position.z > Zmax {
            rebound.z = Float.random(in: -2.0 ... -1.0)
        }
        
        return rebound
    }
    
    func limitVelocity(_ ship: Ship) {
        let mag = Float(ship.velocity.length())
        let limit = Float(0.9);
        if mag > limit {
            ship.velocity = (ship.velocity/mag) * limit
        }
    }
    
    static func getShip(from node: SCNNode) -> Ship? {
        return shipRegistry[node]
    }
    
    func smoothForces(forces: SCNVector3, factor: Float) -> SCNVector3 {
        return velocity + forces * factor
    }
    
    func keepASmallDistance(_ ship: Ship, ships: [Ship]) -> SCNVector3 {
        var forceAway = SCNVector3(x: Float(0), y: Float(0), z: Float(0))
        
        for otherShip in ships {
            if ship.node != otherShip.node {
                if abs(otherShip.node.position.distance(ship.node.position)) < 14 {
                    forceAway = (forceAway - (otherShip.node.position - ship.node.position))
                }
            }
        }
        return forceAway
    }
    
    func updateShipPosition(percievedCenter: SCNVector3, percievedVelocity: SCNVector3, otherShips: [Ship], obstacles: [SCNNode]) {
        var v1 = flyCenterOfMass(otherShips.count, percievedCenter)
        var v2 = keepASmallDistance(self, ships: otherShips)
        var v3 = matchSpeedWithOtherShips(otherShips.count, percievedVelocity)
        var v4 = boundPositions()
        v1 *= (0.1)
        v2 *= (0.1)
        v3 *= (0.1)
        v4 *= (1.0)
        let forward = SCNVector3(x: Float(0), y: Float(0), z: Float(1))
        let velocityNormal = self.velocity.normalized()
        self.velocity = self.velocity + v1 + v2 + v3 + v4;
        limitVelocity(self);
        let nor = forward.cross(velocityNormal)
        let angle = CGFloat(forward.dot(velocityNormal))
        self.node.rotation = SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: Float(acos(angle)))
        self.node.position = self.node.position + (self.velocity)
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
    
    func updateShipPosition(target: SCNVector3, otherShips: [Ship]) {
        // Get nodes from other ships
        let nodes = otherShips.map { $0.node }
        
        // Calculate perceived center of other ships
        let perceivedCenter: SCNVector3
        if otherShips.isEmpty {
            perceivedCenter = node.position
        } else {
            let sumPositions = otherShips.reduce(SCNVector3Zero) { (accumulated, ship) -> SCNVector3 in
                return SCNVector3(accumulated.x + ship.node.position.x,
                                  accumulated.y + ship.node.position.y,
                                  accumulated.z + ship.node.position.z)
            }
            perceivedCenter = SCNVector3(
                x: sumPositions.x / Float(otherShips.count),
                y: sumPositions.y / Float(otherShips.count),
                z: sumPositions.z / Float(otherShips.count)
            )
        }

        // Direction to target
        let directionToTarget = (target - node.position).normalized()

        // Collision avoidance force
        let avoidCollisions = nodes.reduce(SCNVector3Zero) { (force, shipNode) in
            let distance = node.position.distance(shipNode.position)
            if distance < 14 { // Avoid collisions if too close
                return force - (shipNode.position - node.position).normalized() * (1 / distance) // apply more force as ships are closer
            }
            return force
        }

        // Boundaries to keep the ship within limits
        let boundary = SCNVector3(
            x: max(-50, min(50, node.position.x)),
            y: max(-50, min(50, node.position.y)),
            z: max(-70, min(30, node.position.z))
        ) - node.position

        // Calculate new velocity based on perceived center, collision avoidance, target direction, and boundary
        let newVelocity = (perceivedCenter - node.position) * 0.1 +
                          avoidCollisions * 0.1 +
                          directionToTarget * 0.2 +
                          boundary

        // Speed limit
        let speedLimit: Float = 0.9
        let speed = newVelocity.length()
        
        // Apply speed limit
        velocity = (speed > speedLimit) ? (newVelocity / speed) * speedLimit : newVelocity

        // Update ship position
        node.position += velocity
    }

    
//    func updateShipPosition(target: SCNVector3, otherShips: [Ship]) {
//        let nodes = otherShips.map { $0.node }
//        let perceivedCenter = otherShips.isEmpty ? node.position : otherShips.reduce(SCNVector3(x: 0, y: 0, z: 0)) { (accumulated, ship) in
//            SCNVector3(accumulated.x + ship.node.position.x, accumulated.y + ship.node.position.y, accumulated.z + ship.node.position.z)
//        } / Float(otherShips.count)
//
//        let directionToTarget = (target - node.position).normalized()
//        let avoidCollisions = nodes.reduce(SCNVector3Zero) { force, shipPos in
//            let distance = node.position.distance(shipPos.position)
//            return distance < 14 ? force - (shipPos.position - node.position) : force
//        }
//        let boundary = SCNVector3(
//            x: max(-50, min(50, node.position.x)),
//            y: max(-50, min(50, node.position.y)),
//            z: max(-70, min(30, node.position.z))
//        ) - node.position
//        let newVelocity = (perceivedCenter - node.position) * 0.1 + avoidCollisions * 0.1 + directionToTarget * 0.2 + boundary
//        let speedLimit: Float = 0.9
//        let speed = newVelocity.length()
//        velocity = speed > speedLimit ? (newVelocity / speed) * speedLimit : newVelocity
//        node.position += velocity
//    }
    
}
