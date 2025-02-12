//
//  SCNScene+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

// MARK: - Scene extensions

extension SCNScene {
    
    static func nodeWithModelName(_ modelName: String) -> SCNNode {
        return SCNScene(named: modelName)!.rootNode.clone()
    }
}

extension SCNNode {
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = ((max) - (min))
        simdPivot = float4x4(translation: SIMD3((extents / 2) + (min)))
    }
}

extension SCNNode {
    func move(toParent parent: SCNNode) {
        let convertedTransform = convertTransform(SCNMatrix4Identity, to: parent)
        removeFromParentNode()
        transform = convertedTransform
        parent.addChildNode(self)
    }
}





extension float4x4 {
    init(translation vector: SIMD3<Float>) {
        self.init(SIMD4(1, 0, 0, 0),
                  SIMD4(0, 1, 0, 0),
                  SIMD4(0, 0, 1, 0),
                  SIMD4(vector.x, vector.y, vector.z, 1))
    }
}

func / (left: SCNVector3, right: Int) -> SCNVector3 {
    return SCNVector3Make(left.x / Float(right), left.y / Float(right), left.z / Float(right))
}
