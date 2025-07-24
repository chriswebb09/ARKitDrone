//
//  ARWorldMap+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit

// MARK: - ARKit Sendable Conformance
// ARKit types are not Sendable by default, but we need them for async/await operations
// We use @unchecked Sendable because these types are immutable after creation
// and ARKit guarantees thread-safety for these objects once they're created

extension ARWorldMap: @unchecked Sendable {}
extension ARAnchor: @unchecked Sendable {}
extension ARCamera: @unchecked Sendable {}

extension ARWorldMap {
    var boardAnchor: BoardAnchor? {
        return anchors.compactMap { $0 as? BoardAnchor }.first
    }
    
    var keyPositionAnchors: [KeyPositionAnchor] {
        return anchors.compactMap { $0 as? KeyPositionAnchor }
    }
}
