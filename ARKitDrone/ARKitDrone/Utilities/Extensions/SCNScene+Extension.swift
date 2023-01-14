//
//  SCNScene+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

extension SCNScene {
    static func nodeWithModelName(_ modelName: String) -> SCNNode {
        return SCNScene(named: modelName)!.rootNode.clone()
    }
}
