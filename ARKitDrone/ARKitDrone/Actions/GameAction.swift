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
    
    // Ship synchronization
    case shipsPositionSync([ShipSyncData])
    case shipDestroyed(String) // shipId
    case shipTargeted(String, Bool) // shipId, targeted
    
    // Missile synchronization
    case missileFired(MissileFireData)
    case missilePositionUpdate(MissileSyncData)
    case missileHit(MissileHitData)
    
    private enum CodingKey: UInt32, CaseIterable {
        case move
        case movement
        case startMoving
        case stopMoving
        case shipsSync
        case shipDestroyed
        case shipTargeted
        case missileFired
        case missileUpdate
        case missileHit
    }
}

extension GameAction: BitStreamCodable {
    
    func encode(to bitStream: inout WritableBitStream) throws {
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
            
        case .shipsPositionSync(let ships):
            bitStream.appendEnum(CodingKey.shipsSync)
            try ships.encode(to: &bitStream)
            
        case .shipDestroyed(let shipId):
            bitStream.appendEnum(CodingKey.shipDestroyed)
            try shipId.encode(to: &bitStream)
            
        case .shipTargeted(let shipId, let targeted):
            bitStream.appendEnum(CodingKey.shipTargeted)
            try shipId.encode(to: &bitStream)
            bitStream.appendBool(targeted)
            
        case .missileFired(let data):
            bitStream.appendEnum(CodingKey.missileFired)
            try data.encode(to: &bitStream)
            
        case .missilePositionUpdate(let data):
            bitStream.appendEnum(CodingKey.missileUpdate)
            try data.encode(to: &bitStream)
            
        case .missileHit(let data):
            bitStream.appendEnum(CodingKey.missileHit)
            try data.encode(to: &bitStream)
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
            
        case .shipsSync:
            let ships = try [ShipSyncData](from: &bitStream)
            self = .shipsPositionSync(ships)
            
        case .shipDestroyed:
            let shipId = try String(from: &bitStream)
            self = .shipDestroyed(shipId)
            
        case .shipTargeted:
            let shipId = try String(from: &bitStream)
            let targeted = try bitStream.readBool()
            self = .shipTargeted(shipId, targeted)
            
        case .missileFired:
            let data = try MissileFireData(from: &bitStream)
            self = .missileFired(data)
            
        case .missileUpdate:
            let data = try MissileSyncData(from: &bitStream)
            self = .missilePositionUpdate(data)
            
        case .missileHit:
            let data = try MissileHitData(from: &bitStream)
            self = .missileHit(data)
        }
    }
}

extension Array: BitStreamCodable where Element: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let count = try bitStream.readUInt32()
        self = try (0..<count).map { _ in try Element(from: &bitStream) }
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        bitStream.appendUInt32(UInt32(count))
        for element in self {
            try element.encode(to: &bitStream)
        }
    }
}
