//
//  SCNScene+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

// MARK: - Scene extensions
extension SCNScene {
    
    static func nodeWithModelName(_ modelName: String) -> SCNNode {
        return SCNScene(named: modelName)!.rootNode.clone()
    }
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat, queue: DispatchQueue) {
        queue.async {
            if self.lightingEnvironment.contents == nil {
                if let environmentMap = UIImage(named: "art.scnassets/environment_blur.exr") {
                    self.lightingEnvironment.contents = environmentMap
                }
            }
            self.lightingEnvironment.intensity = intensity
        }
    }
}
