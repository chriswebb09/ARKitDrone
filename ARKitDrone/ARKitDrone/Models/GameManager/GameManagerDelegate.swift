//
//  GameManagerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

@MainActor
protocol GameManagerDelegate: AnyObject {
    func manager(_ manager: GameManager, received: BoardSetupAction, from: Player)
    func manager(_ manager: GameManager, joiningPlayer player: Player)
    func manager(_ manager: GameManager, leavingPlayer player: Player)
    func manager(_ manager: GameManager, joiningHost host: Player)
    func manager(_ manager: GameManager, leavingHost host: Player)
    func managerDidStartGame(_ manager: GameManager)
    func manager(_ manager: GameManager, addNode: AddNodeAction)
    func manager(_ manager: GameManager, completed: CompletedAction)
    func manager(_ manager: GameManager, moveNode: MoveData)
    func manager(_ manager: GameManager, hasNetworkDelay: Bool)
}
