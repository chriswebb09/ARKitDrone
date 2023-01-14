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
}

