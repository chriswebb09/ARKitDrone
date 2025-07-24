//
//  SessionState.swift
//  ARKitDrone
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

enum SessionState: CaseIterable {
    case setup
    case lookingForSurface
    case adjustingBoard
    case placingBoard
    case waitingForBoard
    case localizingToBoard
    case setupLevel
    case gameInProgress
}

// MARK: - CustomStringConvertible

extension SessionState: CustomStringConvertible {
    var description: String {
        switch self {
        case .setup: return "setup"
        case .lookingForSurface: return "lookingForSurface"
        case .adjustingBoard: return "adjustingBoard"
        case .placingBoard: return "placingBoard"
        case .waitingForBoard: return "waitingForBoard"
        case .localizingToBoard: return "localizingToBoard"
        case .setupLevel: return "setupLevel"
        case .gameInProgress: return "gameInProgress"
        }
    }
}

// MARK: - Hashable

extension SessionState: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.description)
    }
}