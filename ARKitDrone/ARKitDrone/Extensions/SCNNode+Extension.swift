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
    
    static func addFlash(contactPoint: SCNVector3) -> SCNNode {
        let flash = SCNLight()
        flash.type = .omni
        flash.color = UIColor.white
        flash.intensity = 4000
        flash.attenuationStartDistance = 5
        flash.attenuationEndDistance = 15  // Ensures the light fades over distance
        let flashNode = SCNNode()
        flashNode.light = flash
        flashNode.position =  contactPoint
        return flashNode
    }
    
    
    static func runAndFadeExplosion(flashNode: SCNNode) {
        let fadeAction = SCNAction.customAction(duration: 0.1) { (node, elapsedTime) in
            let percent = 1.0 - (elapsedTime / 0.1)
            node.light?.intensity = 4000 * percent
        }
        
        let removeAction = SCNAction.sequence([fadeAction, SCNAction.removeFromParentNode()])
        flashNode.runAction(removeAction)
        flashNode.runAction(SCNAction.sequence([
            SCNAction.wait(duration: 0.25),
            SCNAction.removeFromParentNode()
        ]))
    }
    
}
