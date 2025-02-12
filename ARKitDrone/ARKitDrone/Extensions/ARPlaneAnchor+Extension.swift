//
//  ARPlaneAnchor+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit

extension ARPlaneAnchor.Classification: Equatable {
    
    public static func == (lhs: ARPlaneAnchor.Classification, rhs: ARPlaneAnchor.Classification) -> Bool {
        switch (lhs, rhs) {
        case
            (.wall, .wall),
            (.floor, .floor),
            (.ceiling, .ceiling),
            (.table, .table),
            (.seat, .seat),
            (.window, .window),
            (.door, .door):
            return true
        case (.none(let lhsStatus), .none(let rhsStatus)):
            return lhsStatus == rhsStatus
        default: return false
        }
    }
    
}
