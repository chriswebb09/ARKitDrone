//
//  BoardSetupAction.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

enum BoardSetupAction: BitStreamCodable {
    case requestBoardLocation
    case boardLocation(GameBoardLocation)
    
    enum CodingKey: UInt32, CaseIterable {
        case requestBoardLocation
        case boardLocation
        
    }
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .requestBoardLocation:
            self = .requestBoardLocation
        case .boardLocation:
            let location = try GameBoardLocation(from: &bitStream)
            self = .boardLocation(location)
        }
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .requestBoardLocation:
            bitStream.appendEnum(CodingKey.requestBoardLocation)
        case .boardLocation(let location):
            bitStream.appendEnum(CodingKey.boardLocation)
            location.encode(to: &bitStream)
        }
    }
}

