//
//  SCNMaterial+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

extension SCNMaterial {
    
    static var occluder: SCNMaterial {
        let material = SCNMaterial()
        material.colorBufferWriteMask = []
        return material
    }
    
    static func colored(with color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        return material
    }
    
    static var visibleMesh: SCNMaterial {
        let material = SCNMaterial()
        material.fillMode = .lines
        material.diffuse.contents = UIColor.red
        return material
    }
    
}

