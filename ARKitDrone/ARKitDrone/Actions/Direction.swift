//
//  Direction.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import Foundation
import simd

enum Direction: BitStreamCodable {
    case forward
    case altitude
    case rotation
    case side
    
    enum CodingKey: UInt32, CaseIterable {
        case forward
        case altitude
        case rotation
        case side
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
            
        case .forward:
            self = .forward
        case .altitude:
            self = .altitude
        case .rotation:
            self = .rotation
        case .side:
            self = .side
        }
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .forward:
            bitStream.appendEnum(CodingKey.forward)
        case .altitude:
            bitStream.appendEnum(CodingKey.altitude)
        case .rotation:
            bitStream.appendEnum(CodingKey.rotation)
        case .side:
            bitStream.appendEnum(CodingKey.side)
        }
    }
}
