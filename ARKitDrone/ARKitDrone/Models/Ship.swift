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
    var square: TargetNode!
    var targetAdded = false
    var fired = false
    var id: String!
    var num: Int!
    
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
    
    func boundPositions(_ ship: Ship) -> SCNVector3 {
        var rebound = SCNVector3(x: Float(0), y: Float(0), z:Float(0))
        let Xmin = -30;
        let Ymin = -30;
        let Zmin = -100;
        let Xmax = 50;
        let Ymax = 50;
        let Zmax = 50;
        if ship.node.position.x < Float(Xmin) {
            rebound.x = 1;
        }
        
        if ship.node.position.x > Float(Xmax) {
            rebound.x = -1;
        }
        
        if ship.node.position.y < Float(Ymin) {
            rebound.y = 1;
        }
        
        if ship.node.position.y > Float(Ymax) {
            rebound.y = -1;
        }
        
        if ship.node.position.z < Float(Zmin) {
            rebound.z = 1;
        }
        
        if ship.node.position.z > Float(Zmax) {
            rebound.z = -1;
        }
        return rebound;
        
    }
    
    func limitVelocity(_ ship: Ship) {
        let mag = Float(ship.velocity.length())
        let limit: Float = 0.8
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
                if abs(otherShip.node.position.distance(ship.node.position)) < 40 {
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
        var v4 = boundPositions(self)
        v1 *= (0.1)
        v2 *= (0.1)
        v3 *= (0.1)
        v4 *= (1.0)
        let forward = SCNVector3(x: Float(0), y: Float(0), z: Float(1))
        let velocityNormal = self.velocity.normalized()
        self.velocity = self.velocity + v1 + v2 + v3 + v4;
        limitVelocity(self)
        let nor = forward.cross(velocityNormal)
        let angle = CGFloat(forward.dot(velocityNormal))
        self.node.rotation = SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: Float(acos(angle)))
        self.node.position = self.node.position + (self.velocity)
        if targetAdded {
            square.unhide()
            square.displayNodeHierarchyOnTop(true)
            self.square.recentFocusSquarePositions = Array(square.recentFocusSquarePositions.suffix(10))
            let position = self.node.simdWorldTransform.translation
            square.recentFocusSquarePositions.append(position)
            let average = square.recentFocusSquarePositions.reduce([0, 0, 0], { $0 + $1 }) / Float(square.recentFocusSquarePositions.count)
            square.simdPosition = average
            square.simdScale = [20.0, 20.0, 20.0]
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            self.square.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            self.square.position = SCNVector3(x: self.node.position.x, y: self.node.position.y, z: self.node.position.z)
            SCNTransaction.commit()
            square.performOpenAnimation()
        }
    }
    
    func setTargetAboveSelected() {
        if self.targetAdded {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.01
            self.targetNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            self.targetNode.position = SCNVector3(x: self.node.position.x, y: self.node.position.y + 1, z: self.node.position.z - 10)
            SCNTransaction.commit()
        }
    }
    
    func updateShipPosition(target: SCNVector3, otherShips: [Ship]) {
        let nodes = otherShips.map { $0.node }
        
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
        let directionToTarget = (target - node.position).normalized()
        let avoidCollisions = nodes.reduce(SCNVector3Zero) { (force, shipNode) in
            let distance = node.position.distance(shipNode.position)
            if distance < 14 { // Avoid collisions if too close
                return force - (shipNode.position - node.position).normalized() * (1 / distance) // apply more force as ships are closer
            }
            return force
        }
        let boundary = SCNVector3(
            x: max(-10, min(10, node.position.x)),
            y: max(-10, min(10, node.position.y)),
            z: max(-10, min(10, node.position.z))
        ) - node.position
        let newVelocity = (perceivedCenter - node.position) * 0.1 +
        avoidCollisions * 0.1 +
        directionToTarget * 0.2 +
        boundary
        
        let speedLimit: Float = 0.4
        let speed = newVelocity.length()
        
        velocity = (speed > speedLimit) ? (newVelocity / speed) * speedLimit : newVelocity
        node.position += velocity
        if targetAdded {
            square.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            SCNTransaction.begin()
            square.simdScale = [1.0, 1.0, 1.0]
            SCNTransaction.animationDuration = 0.1
            square.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            square.simdWorldPosition = node.simdWorldPosition
            square.simdWorldOrientation = node.simdWorldOrientation
            square.simdWorldTransform = node.simdWorldTransform
            SCNTransaction.commit()
        }
    }
}


extension Ship {
    
    func attack(target: SCNNode) {
        let distanceToTarget = node.position.distance(target.position)
        let attackRange: Float = 50.0
        self.node.simdWorldOrientation = target.simdWorldOrientation
        self.node.look(at: target.position)
        if distanceToTarget <= attackRange {
            if !isDestroyed {
                if !fired {
                    fired = true
                    self.fireAt(target)
                    _ = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
                        guard let self = self else { return }
                        fired = false
                        timer.invalidate()
                    })
                    //                    let targetPos = target.presentation.simdWorldPosition
                    //                    let currentPos = self.node.presentation.simdWorldPosition
                    //                    flyTowards(target.position, orientation: target.simdWorldOrientation, currentPos: currentPos, targetPos: targetPos)
                }
                
            }
        }
    }
    
    private func fireAt(_ target: SCNNode) {
        let missile = createMissile()
        missile.position = self.node.position
        //        let speed: Float = 50
        let targetPos = target.presentation.simdWorldPosition
        let currentPos = missile.presentation.simdWorldPosition
        let targetDirection = simd_normalize(currentPos - targetPos)
        //        missile.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        let direction = SCNVector3(x: -Float(targetDirection.x), y: -Float(targetDirection.y), z: -Float(targetDirection.z))
        //        missile.node.simdWorldTransform = self.node.simdWorldTransform
        missile.simdWorldOrientation = target.simdWorldOrientation
        missile.look(at: target.position)
        missile.physicsBody?.applyForce(direction * 1000, at: target.presentation.position, asImpulse: true)
        missile.simdWorldOrientation = target.simdWorldOrientation
        missile.look(at: target.position)
        //        let movement = direction * speed
        //        missile.simdWorldPosition += movement
        //        missile.look(at: self.node.presentation.position)
        //        missile.particle?.orientationDirection = SCNVector3(-direction.x, -direction.y, -direction.z)
        //        let direction = (target.position - self.node.position).normalized()
        //        missileNode.physicsBody?.applyForce(direction * 10, at: missileNode.position, asImpulse: true)
    }
    
    private func createMissile() -> SCNNode {
        let missileGeometry = SCNCapsule(capRadius: 0.6, height: 4)
        
        let material = missileGeometry.firstMaterial!
        material.diffuse.contents = TargetNode.fillColor
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = TargetNode.fillColor
        let missileNode = SCNNode(geometry: missileGeometry)
        missileNode.name = "Missile"
        let missilePhysicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        missileNode.physicsBody = missilePhysicsBody
        missileNode.physicsBody?.isAffectedByGravity = false
        missileNode.physicsBody?.categoryBitMask = CollisionTypes.missile.rawValue
        missileNode.physicsBody?.collisionBitMask = CollisionTypes.base.rawValue
        missileNode.physicsBody?.contactTestBitMask = CollisionTypes.base.rawValue
        node.getRootNode().addChildNode(missileNode)
        missileNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        return missileNode
    }
    
    private func flyTowards(_ targetPosition: SCNVector3, orientation: simd_quatf, currentPos: simd_float3, targetPos: simd_float3) {
        // Correct the direction: from the object to the target
        let targetDirection = simd_normalize(targetPos - currentPos)
        
        // Convert target direction to SCNVector3
        let direction = SCNVector3(x: Float(targetDirection.x), y: Float(targetDirection.y), z: Float(targetDirection.z))
        
        // Update the orientation if needed (optional if you want to manually handle it)
        node.simdWorldOrientation = orientation
        
        // Ensure the node faces the target
        node.look(at: targetPosition)
        
        // Scale the direction for movement speed
        velocity = direction * 5 // Adjust the speed multiplier
        
        // Update the position based on the velocity
        node.position += velocity
    }
}

