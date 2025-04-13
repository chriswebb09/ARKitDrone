//
//  Tank.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 9/30/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit
import os.log

class GameObject: NSObject {
    
    var objectRootNode: SCNNode!
    var physicsNode: SCNNode?
    var geometryNode: SCNNode?
    var owner: Player?
    
    var isAlive: Bool
    
    static var indexCounter = 0
    var index = 0
    
    init(node: SCNNode, index: Int?, alive: Bool, owner: Player?) {
        objectRootNode = node
        self.isAlive = alive
        self.owner = owner
        if let index = index {
            self.index = index
        } else {
            self.index = GameObject.indexCounter
            GameObject.indexCounter += 1
        }
        super.init()
       // attachGeometry()
    }
    
    func apply(movementData nodeData: MovementData, isHalfway: Bool) {
        objectRootNode.apply(movementData: nodeData, isHalfway: isHalfway)
//        // if we're not alive, avoid applying physics updates.
//        // this will allow objects on clients to get culled properly
//        guard isAlive else { return }
//        
//        if isHalfway {
//            objectRootNode.simdWorldPosition = (nodeData.position + objectRootNode.simdWorldPosition) * 0.5
//            objectRootNode.simdEulerAngles = (nodeData.eulerAngles + objectRootNode.simdEulerAngles) * 0.5
//        } else {
//            objectRootNode.simdWorldPosition = nodeData.position
//            objectRootNode.simdEulerAngles = nodeData.eulerAngles
//        }
    }
    
    func generateMovementData() -> MovementData? {
        return objectRootNode.generateMovementData(isAlive: isAlive)
    }
}


