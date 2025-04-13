//
//  Action.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

enum Action {
    case gameAction(GameAction)
    case boardSetup(BoardSetupAction)
    case addNode(AddNodeAction)
    case completed(CompletedAction)
}

extension Action: BitStreamCodable {
    
    private enum CodingKey: UInt32, CaseIterable {
        case gameAction
        case boardSetup
        case addNode
        case completed
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        switch self {
        case .gameAction(let gameAction):
            bitStream.appendEnum(CodingKey.gameAction)
            try gameAction.encode(to: &bitStream)
        case .boardSetup(let boardSetup):
            bitStream.appendEnum(CodingKey.boardSetup)
            boardSetup.encode(to: &bitStream)
        case .addNode(let addNode):
            bitStream.appendEnum(CodingKey.addNode)
            try addNode.encode(to: &bitStream)
        case .completed(let completedAction):
            bitStream.appendEnum(CodingKey.completed)
            try completedAction.encode(to: &bitStream)
        }
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let code: CodingKey = try bitStream.readEnum()
        switch code {
        case .gameAction:
            let gameAction = try GameAction(from: &bitStream)
            self = .gameAction(gameAction)
        case .boardSetup:
            let boardAction = try BoardSetupAction(from: &bitStream)
            self = .boardSetup(boardAction)
        case .addNode:
            let addNodeAction = try AddNodeAction(from: &bitStream)
            self = .addNode(addNodeAction)
        case .completed:
            let completedAction = try CompletedAction(from: &bitStream)
            self = .completed(completedAction)
        }
    }
    
}
