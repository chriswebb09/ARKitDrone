//
//  CollisionCategory.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/16/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

struct CollisionCategory: OptionSet {
    let rawValue: Int
    static let missileCategory  = CollisionCategory(rawValue: 1 << 0)
    static let targetCategory = CollisionCategory(rawValue: 1 << 1)
    static let otherCategory = CollisionCategory(rawValue: 1 << 2)
}
