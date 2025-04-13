//
//  GameBoardLocation.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

enum GameBoardLocation: BitStreamCodable {
    case worldMapData(Data)
    case manual
    
    enum CodingKey: UInt32, CaseIterable {
        case worldMapData
        case manual
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .worldMapData:
            let data = try bitStream.readData()
            self = .worldMapData(data)
        case .manual:
            self = .manual
        }
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .worldMapData(let data):
            bitStream.appendEnum(CodingKey.worldMapData)
            bitStream.append(data)
        case .manual:
            bitStream.appendEnum(CodingKey.manual)
        }
    }
}
