//
//  SCNNode+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNNode {
    
    var width: Float {
        (boundingBox.max.x - boundingBox.min.x) * scale.x
    }
    
    var height: Float {
        (boundingBox.max.y - boundingBox.min.y) * scale.y
    }
    
    static func centerPivot(for node: SCNNode) {
         var min = SCNVector3Zero
         var max = SCNVector3Zero
         node.__getBoundingBoxMin(&min, max: &max)
         node.pivot = SCNMatrix4MakeTranslation(
             min.x + (max.x - min.x)/2,
             min.y + (max.y - min.y)/2,
             min.z + (max.z - min.z)/2
         )
     }
     
     static func updatePositionAndOrientationOf(_ node: SCNNode, withPosition position: SCNVector3, relativeTo referenceNode: SCNNode) {
         let referenceNodeTransform = matrix_float4x4(referenceNode.transform)
         
         var translationMatrix = matrix_identity_float4x4
         translationMatrix.columns.3.x = position.x
         translationMatrix.columns.3.y = position.y
         translationMatrix.columns.3.z = position.z
         
         let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
         node.transform = SCNMatrix4(updatedTransform)
     }
    
    func normalizedDirectionInWorldXZPlane(_ relativeDirection: SCNVector3) -> SCNVector3 {
           let p1 = self.presentation.convertPosition(relativeDirection, to: nil)
           let p0 = self.presentation.convertPosition(SCNVector3Zero, to: nil)
           var direction = float3(Float(p1.x - p0.x), 0.0, Float(p1.z - p0.z))
           
           if direction.x != 0.0 || direction.z != 0.0 {
               direction = normalize(direction)
           }
           return SCNVector3(direction)
       }
}

