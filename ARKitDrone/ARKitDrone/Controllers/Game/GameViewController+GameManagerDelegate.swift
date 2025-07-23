//
//  GameViewController+GameManagerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/11/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import os.log
import RealityKit
import ARKit

extension GameViewController: GameManagerDelegate {
    func manager(_ manager: GameManager, shipsUpdated ships: [ShipSyncData]) {
        
    }
    
    func manager(_ manager: GameManager, shipDestroyed shipId: String) {
        
    }
    
    func manager(_ manager: GameManager, shipTargeted shipId: String, targeted: Bool) {
        
    }
    
    func manager(_ manager: GameManager, missileFired data: MissileFireData) {
        
    }
    
    func manager(_ manager: GameManager, missilePositionUpdated data: MissileSyncData) {
        
    }
    
    func manager(_ manager: GameManager, missileHit data: MissileHitData) {
        
    }
    
    
    func manager(_ manager: GameManager, hasNetworkDelay: Bool) { }
    
    func manager(_ manager: GameManager, moveNode: MoveData) {
        os_log(.info, "move forward from joytick %s", String.init(describing: moveNode))
        //        DispatchQueue.main.async {
        //            if let dir = moveNode.direction {
        //                switch dir {
        //                case .forward:
        //                    self.sceneView.competitor.moveForward(value: (moveNode.velocity.vector.y))
        //                case .altitude:
        //                    self.sceneView.competitor.changeAltitude(value: moveNode.velocity.vector.y)
        //                case .rotation:
        //                    self.sceneView.competitor.rotate(value: moveNode.velocity.vector.x)
        //                case .side:
        //                    self.sceneView.competitor.moveSides(value: moveNode.velocity.vector.x)
        //                }
        //            } else {
        //                self.sceneView.competitor.moveForward(value: moveNode.velocity.vector.y)
        //            }
        //        }
    }
    
    func manager(_ manager: GameManager, completed: CompletedAction) {
        print("completed")
        self.stateManager.transitionTo(SessionState.gameInProgress)
    }
    
    private func process(boardAction: BoardSetupAction, from peer: Player) {
        os_log(.info, "board setup action from %s", peer.username)
        switch boardAction {
        case .boardLocation(let location):
            os_log(.info, "board location")
            switch location {
            case .worldMapData(let data):
                os_log(.info, "Received WorldMap data. Size: %d", data.count)
                self.loadWorldMap(from: data)
                self.stateManager.transitionTo(SessionState.lookingForSurface)
            case .manual:
                os_log(.info, "Received a manual board placement")
                self.stateManager.transitionTo(SessionState.lookingForSurface)
            }
        case .requestBoardLocation:
            os_log(.info, "sending world to peer")
            self.sendWorldTo(peer: peer)
        }
    }
    
    func manager(_ manager: GameManager, addNode: AddNodeAction) {
        os_log(.info, "processing addNode action - helicopter creation now handled by createdHelicopter delegate")
        
        // Extract position from transform matrix
        let tappedPosition = SIMD3<Float>(
            addNode.simdWorldTransform.columns.3.x,
            addNode.simdWorldTransform.columns.3.y,
            addNode.simdWorldTransform.columns.3.z
        )
        
        // Only handle non-helicopter related setup here
        // Helicopter creation is now handled by manager(_:createdHelicopter:for:)
        Task { @MainActor in
            let endPos = SIMD3<Float>(
                x: tappedPosition.x,
                y: tappedPosition.y,
                z: tappedPosition.z
            )
            gameManager?.send(
                completed: CompletedAction.init(position: endPos)
            )
        }
    }
    
    func manager(_ manager: GameManager, received: BoardSetupAction, from: Player) {
        os_log(.info, "received action to process %s", String(describing: received))
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.process(boardAction: received, from: from)
        }
    }
    
    func manager(_ manager: GameManager, joiningPlayer player: Player) { }
    
    func manager(_ manager: GameManager, leavingPlayer player: Player) { }
    
    func manager(_ manager: GameManager, joiningHost host: Player) {
        os_log(.info, "GameManagerDelegate joining host")
        // MARK: request worldmap when joining the host
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.stateManager.sessionState == SessionState.waitingForBoard {
                manager.send(boardAction: .requestBoardLocation)
            }
            //guard !UserDefaults.standard.disableInGameUI else { return }
        }
    }
    
    func manager(_ manager: GameManager, leavingHost host: Player) { }
    
    func managerDidStartGame(_ manager: GameManager) { }
    
    // MARK: - Multiplayer Helicopter Delegate Methods
    
    func manager(_ manager: GameManager, createdHelicopter: HelicopterObject, for player: Player) {
        os_log(.info, "Helicopter created for player: %s", player.username)
        
        // Handle additional setup for newly created helicopters
        // For example, you might want to:
        // - Add UI indicators for remote players
        // - Set up targeting systems
        // - Initialize visual effects
        
        if player == myself {
            os_log(.info, "Local player helicopter created")
        } else {
            os_log(.info, "Remote player helicopter created: %s", player.username)
        }
    }
    
    func manager(_ manager: GameManager, removedHelicopter: HelicopterObject, for player: Player) {
        os_log(.info, "Helicopter removed for player: %s", player.username)
        
        // Handle cleanup when helicopters are removed
        // For example:
        // - Remove UI indicators
        // - Clean up targeting systems
        // - Stop any ongoing effects
        
        if player == myself {
            os_log(.info, "Local player helicopter removed")
        } else {
            os_log(.info, "Remote player helicopter removed: %s", player.username)
        }
    }
    
    func manager(_ manager: GameManager, helicopterMovementUpdated: HelicopterObject, for player: Player) {
        // Handle helicopter movement updates for UI or effects
        // This is called whenever any helicopter moves
        
        if player != myself {
            // Only log for remote players to avoid spam from local movement
            os_log(.debug, "Remote helicopter movement updated for player: %s", player.username)
            
            // You might use this for:
            // - Updating minimap positions
            // - Triggering sound effects
            // - Updating targeting systems
            // - Collision detection with local player
        }
    }
}
