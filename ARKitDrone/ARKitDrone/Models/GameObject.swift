//
//  Tank.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 9/30/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import Foundation
import GameplayKit
import RealityKit
import os.log

class GameObject: NSObject {
    
    var objectRootEntity: Entity!
    var physicsEntity: Entity?
    var geometryEntity: Entity?
    var owner: Player?
    
    var isAlive: Bool
    
    @MainActor static var indexCounter = 0
    var index = 0
    
    // RealityKit initializer
    @MainActor
    init(entity: Entity, index: Int?, alive: Bool, owner: Player?) {
        objectRootEntity = entity
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
    
    @MainActor
    func apply(movementData nodeData: MovementData, isHalfway: Bool) {
        // Apply movement data to RealityKit Entity
        guard nodeData.isAlive else { return }
        
        if isHalfway {
            // Smooth interpolation for halfway positioning
            let currentPos = objectRootEntity.transform.translation
            let currentRot = objectRootEntity.transform.rotation.eulerAngles
            
            objectRootEntity.transform.translation = (nodeData.position + currentPos) * 0.5
            
            // Convert euler angles to quaternion for RealityKit
            let newEuler = (nodeData.eulerAngles + currentRot) * 0.5
            objectRootEntity.transform.rotation = simd_quatf(angle: newEuler.y, axis: SIMD3(0, 1, 0)) *
                                                  simd_quatf(angle: newEuler.x, axis: SIMD3(1, 0, 0)) *
                                                  simd_quatf(angle: newEuler.z, axis: SIMD3(0, 0, 1))
        } else {
            // Direct positioning
            objectRootEntity.transform.translation = nodeData.position
            
            // Convert euler angles to quaternion for RealityKit
            objectRootEntity.transform.rotation = simd_quatf(angle: nodeData.eulerAngles.y, axis: SIMD3(0, 1, 0)) *
                                                  simd_quatf(angle: nodeData.eulerAngles.x, axis: SIMD3(1, 0, 0)) *
                                                  simd_quatf(angle: nodeData.eulerAngles.z, axis: SIMD3(0, 0, 1))
        }
    }
    
    @MainActor
    func generateMovementData() -> MovementData? {
        return MovementData(entity: objectRootEntity, alive: isAlive)
    }
}


