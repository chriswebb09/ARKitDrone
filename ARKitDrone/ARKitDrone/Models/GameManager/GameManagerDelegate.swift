//
//  GameManagerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import Foundation
import RealityKit

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
    
    // MARK: - Multiplayer Helicopter Delegate Methods
    func manager(_ manager: GameManager, createdHelicopter: HelicopterObject, for player: Player)
    func manager(_ manager: GameManager, removedHelicopter: HelicopterObject, for player: Player)
    func manager(_ manager: GameManager, helicopterMovementUpdated: HelicopterObject, for player: Player)
    
    // MARK: - Ship Synchronization Delegate Methods
    func manager(_ manager: GameManager, shipsUpdated ships: [ShipSyncData])
    func manager(_ manager: GameManager, shipDestroyed shipId: String)
    func manager(_ manager: GameManager, shipTargeted shipId: String, targeted: Bool)
    
    // MARK: - Missile Synchronization Delegate Methods
    func manager(_ manager: GameManager, missileFired data: MissileFireData)
    func manager(_ manager: GameManager, missilePositionUpdated data: MissileSyncData)
    func manager(_ manager: GameManager, missileHit data: MissileHitData)
}
