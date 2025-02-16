//
//  SCNNode+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/15/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//
import SceneKit

extension SCNNode {
    func removeAll() {
        isHidden = true
        removeAllAnimations()
        removeAllActions()
        removeAllParticleSystems()
        removeFromParentNode()
    }
    
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = ((max) - (min))
        simdPivot = float4x4(translation: SIMD3((extents / 2) + (min)))
    }
    
    func move(toParent parent: SCNNode) {
        let convertedTransform = convertTransform(SCNMatrix4Identity, to: parent)
        removeFromParentNode()
        transform = convertedTransform
        parent.addChildNode(self)
    }
    
    static func distanceBetween(_ nodeA: SCNNode, _ nodeB: SCNNode) -> Float {
        let posA = nodeA.worldPosition
        let posB = nodeB.worldPosition
        return (posA - posB).length()
    }
    
    func getRootNode() -> SCNNode {
        var currentNode = self
        while let parent = currentNode.parent {
            currentNode = parent
        }
        return currentNode
    }
    
    func getTargetVector(target: SCNNode) -> (SCNVector3, SCNVector3) {
        let mat = SCNMatrix4(target.simdWorldTransform)
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
        return (dir, pos)
    }
    
}
