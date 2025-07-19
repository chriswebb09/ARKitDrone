//
//  CompletedAction.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

struct CompletedAction {
    var position: SIMD3<Float>
}

extension CompletedAction: BitStreamCodable {
    
    func encode(to bitStream: inout WritableBitStream) throws {
        position.encode(to: &bitStream)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        position = try SIMD3<Float>(from: &bitStream)
    }
}
