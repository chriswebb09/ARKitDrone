//
//  GameAction.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

enum GameAction {
    case joyStickMoved(MoveData)
    case movement(MovementSyncData)
    
    private enum CodingKey: UInt32, CaseIterable {
        case move
//        case fire
    }
}


extension GameAction: BitStreamCodable {
    
    func encode(to bitStream: inout WritableBitStream) throws {
        // switch game action
        switch self {
        case .joyStickMoved(let data):
            bitStream.appendEnum(CodingKey.move)
            try data.encode(to: &bitStream)
            
        case .movement(let data):
            bitStream.appendEnum(CodingKey.move)
            try data.encode(to: &bitStream)
        }
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .move:
            let data = try MoveData(from: &bitStream)
            self = .joyStickMoved(data)
        }
    }
    
}
