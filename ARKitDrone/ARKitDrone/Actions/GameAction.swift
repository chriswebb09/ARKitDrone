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
    case helicopterStartMoving(Bool)
    case helicopterStopMoving(Bool)
    
    private enum CodingKey: UInt32, CaseIterable {
        case move
        case movement
        case startMoving
        case stopMoving
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
            bitStream.appendEnum(CodingKey.movement)
            try data.encode(to: &bitStream)
        case .helicopterStartMoving(let isMoving):
            bitStream.appendEnum(CodingKey.startMoving)
            bitStream.appendBool(isMoving)
        case .helicopterStopMoving(let isMoving):
            bitStream.appendEnum(CodingKey.stopMoving)
            bitStream.appendBool(isMoving)
        }
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .move:
            let data = try MoveData(from: &bitStream)
            self = .joyStickMoved(data)
        case .movement:
            let movement = try MovementSyncData(from: &bitStream)
            self = .movement(movement)
        case .startMoving:
            let isMoving = try bitStream.readBool()
            self = .helicopterStartMoving(isMoving)
        case .stopMoving:
            let isMoving = try bitStream.readBool()
            self = .helicopterStopMoving(isMoving)
        }
    }
    
}
