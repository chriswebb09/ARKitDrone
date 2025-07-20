//
//  GameManager.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 9/29/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import Foundation
import GameplayKit
import simd
import ARKit
import AVFoundation
import os.signpost
import RealityKit

/// - Tag: GameManager
@MainActor
class GameManager: NSObject {
    private(set) var isInitialized = false
    
    private let session: NetworkSession?
    private var scene: RealityKit.Scene
    
    var helicopters = [Player: HelicopterObject]()
    
    private let catapultsLock = NSLock()
    private var gameCommands = [GameCommand]()
    private let commandsLock = NSLock()
    
    private let movementSyncData = MovementSyncSceneData()
    
    let currentPlayer = UserDefaults.standard.myself
    
    let isNetworked: Bool
    let isServer: Bool
    
    init(arView: ARView, session: NetworkSession?) {
        self.scene = arView.scene
        self.session = session
        self.isNetworked = session != nil
        self.isServer = session?.isServer ?? true // Solo game act like a server
        super.init()
        self.session?.delegate = self
    }
    
    func queueAction(gameAction: GameAction) {
        commandsLock.lock()
        defer {
            commandsLock.unlock()
        }
        gameCommands.append(
            GameCommand(
                player: currentPlayer,
                action: .gameAction(gameAction)
            )
        )
    }
    
    @MainActor
    private func syncMovement() {
        os_signpost(
            .begin,
            log: .render_loop,
            name: .physics_sync,
            signpostID: .render_loop,
            "Movement sync started"
        )
        defer {
            os_signpost(
                .end,
                log: .render_loop,
                name: .physics_sync,
                signpostID: .render_loop,
                "Movement sync finished"
            )
        }
        
        if isNetworked && movementSyncData.isInitialized {
            if isServer {
                let movementData = movementSyncData.generateData()
                session?.send(
                    action: .gameAction(
                        .movement(movementData)
                    )
                )
            } else {
                movementSyncData.updateFromReceivedData()
            }
        }
    }
    
    @MainActor
    func resetWorld(arView: ARView) {
        self.scene = arView.scene
    }
    
    weak var delegate: GameManagerDelegate?
    
    func send(gameAction: GameAction) {
        session?.send(
            action: .gameAction(gameAction)
        )
    }
    
    func send(completed: CompletedAction) {
        session?.send(
            action: .completed(completed)
        )
    }
    
    func send(addNode: AddNodeAction) {
        session?.send(
            action: .addNode(addNode)
        )
    }
    
    func send(boardAction: BoardSetupAction) {
        session?.send(
            action: .boardSetup(boardAction)
        )
    }
    
    func send(boardAction: BoardSetupAction, to player: Player) {
        session?.send(
            action: .boardSetup(boardAction),
            to: player
        )
    }
    
    // MARK: - Helicopter Management
    func createHelicopter(addNodeAction: AddNodeAction, owner: Player) async {
        os_log(.info, "Creating helicopter object for player %s", owner.username)
        
        // Offset the world transform upward slightly above the surface
        var modifiedTransform = addNodeAction.simdWorldTransform
        modifiedTransform.columns.3.y += 0.5
        
        // Create HelicopterObject instance with modified transform
        let helicopterObject = await HelicopterObject(
            owner: owner,
            worldTransform: modifiedTransform
        )
        
        // Store in helicopters collection
        helicopters[owner] = helicopterObject
        
        // Add to scene
        helicopterObject.addToScene(scene)
        
        os_log(.info, "Helicopter created and added to scene for player %s", owner.username)
        
        // Notify delegate for any additional setup
        await MainActor.run {
            self.delegate?.manager(self, addNode: addNodeAction)
            self.delegate?.manager(self, createdHelicopter: helicopterObject, for: owner)
        }
    }

    func moveHelicopter(player: Player, movement: MoveData) {
        guard let helicopter = helicopters[player] else {
            os_log(.error, "No helicopter found for player %s", player.username)
            return
        }
        
        os_log(.info, "Moving helicopter for player %s", player.username)
        helicopter.updateMovement(moveData: movement)
        
        // Notify delegate of movement update
        Task { @MainActor in
            self.delegate?.manager(self, helicopterMovementUpdated: helicopter, for: player)
        }
    }
    
    /// Switch helicopter animation state (rotor speed, etc.)
    func switchHelicopterAnimation(player: Player, isMoving: Bool) {
        guard let helicopter = helicopters[player] else {
            os_log(.error, "No helicopter found for player %s", player.username)
            return
        }
        
        os_log(.info, "Switching helicopter animation for player %s: %@", player.username, isMoving ? "moving" : "idle")
        
        helicopter.updateMovementState(isMoving: isMoving)
        
        // Send animation state to all players
        if isMoving {
            send(gameAction: .helicopterStartMoving(true))
        } else {
            send(gameAction: .helicopterStopMoving(false))
        }
    }
    
    /// Remove helicopter when player leaves
    func removeHelicopter(for player: Player) {
        guard let helicopter = helicopters[player] else { return }
        
        os_log(.info, "Removing helicopter for player %s", player.username)
        
        helicopter.removeFromScene()
        helicopters.removeValue(forKey: player)
        
        // Notify delegate
        Task { @MainActor in
            self.delegate?.manager(self, removedHelicopter: helicopter, for: player)
        }
    }
    
    /// Get all helicopters for collision detection, targeting, etc.
    func getAllHelicopters() -> [HelicopterObject] {
        return Array(helicopters.values)
    }
    
    /// Get helicopter for specific player
    func getHelicopter(for player: Player) -> HelicopterObject? {
        return helicopters[player]
    }
    
    // MARK: - Ship Synchronization
    
    /// Synchronize ship positions across all clients (called by host)
    func synchronizeShips(_ ships: [Ship]) {
        guard isNetworked && isServer else { return }
        
        // Convert Ship objects to sync data
        let syncData = ships.map { ship in
            ShipSyncData(
                shipId: ship.id,
                position: ship.entity.transform.translation,
                velocity: ship.velocity,
                rotation: ship.entity.transform.rotation,
                isDestroyed: ship.isDestroyed,
                targeted: ship.targeted
            )
        }
        
        // Send to all clients
        send(gameAction: .shipsPositionSync(syncData))
    }
    
    /// Update ship state across network
    func updateShipState(shipId: String, isDestroyed: Bool) {
        guard isNetworked else { return }
        send(gameAction: .shipDestroyed(shipId))
    }
    
    /// Update ship targeting state across network
    func updateShipTargeting(shipId: String, targeted: Bool) {
        guard isNetworked else { return }
        send(gameAction: .shipTargeted(shipId, targeted))
    }
    
    // MARK: - Missile Synchronization
    
    /// Fire missile across network
    func fireMissile(missileId: String, from playerId: String, startPosition: SIMD3<Float>, startRotation: simd_quatf, targetShipId: String) {
        guard isNetworked else { return }
        
        let fireData = MissileFireData(
            missileId: missileId,
            playerId: playerId,
            startPosition: startPosition,
            startRotation: startRotation,
            targetShipId: targetShipId,
            fireTime: CACurrentMediaTime()
        )
        
        send(gameAction: .missileFired(fireData))
    }
    
    /// Update missile position across network
    func updateMissilePosition(missileId: String, position: SIMD3<Float>, rotation: simd_quatf) {
        guard isNetworked else { return }
        
        let syncData = MissileSyncData(
            missileId: missileId,
            position: position,
            rotation: rotation,
            timestamp: CACurrentMediaTime()
        )
        
        send(gameAction: .missilePositionUpdate(syncData))
    }
    
    /// Handle missile hit across network
    func handleMissileHit(missileId: String, shipId: String, hitPosition: SIMD3<Float>, playerId: String) {
        guard isNetworked else { return }
        
        let hitData = MissileHitData(
            missileId: missileId,
            shipId: shipId,
            hitPosition: hitPosition,
            playerId: playerId,
            timestamp: CACurrentMediaTime()
        )
        
        send(gameAction: .missileHit(hitData))
    }
    
    // MARK: - inbound from network
    private func process(command: GameCommand) {
        os_signpost(
            .begin,
            log: .render_loop,
            name: .process_command,
            signpostID: .render_loop,
            "Action End : %s",
            command.action.description
        )
        defer {
            os_signpost(
                .end,
                log: .render_loop,
                name: .process_command,
                signpostID: .render_loop,
                "Action End: %s",
                command.action.description
            )
        }
        
        switch command.action {
        case .gameAction(let gameAction):
            os_log(
                .info,
                "game action from %s for %s",
                command.player?.username ?? "unknown",
                String(describing: gameAction)
            )
            guard let player = command.player else { return }
            if case let .joyStickMoved(data) = gameAction {
                Task { @MainActor in
                    self.moveHelicopter(player: player, movement: data)
                }
            }
            
            if case let .helicopterStartMoving(isMoving) = gameAction {
                Task { @MainActor in
                    self.switchHelicopterAnimation(player: player, isMoving: isMoving)
                }
            }
            
            if case let .helicopterStopMoving(isMoving) = gameAction {
                Task { @MainActor in
                    self.switchHelicopterAnimation(player: player, isMoving: !isMoving)
                }
            }
            
            // Ship synchronization message handling
            if case let .shipsPositionSync(ships) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, shipsUpdated: ships)
                }
            }
            
            if case let .shipDestroyed(shipId) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, shipDestroyed: shipId)
                }
            }
            
            if case let .shipTargeted(shipId, targeted) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, shipTargeted: shipId, targeted: targeted)
                }
            }
            
            // Missile synchronization message handling
            if case let .missileFired(data) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, missileFired: data)
                }
            }
            
            if case let .missilePositionUpdate(data) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, missilePositionUpdated: data)
                }
            }
            
            if case let .missileHit(data) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, missileHit: data)
                }
            }
            
            //            if case let .movement(movementSyncData) = gameAction {
            //                self.delegate?.manager(self, received: movementSyncData, from: player)
            //            }
        case .boardSetup(let boardAction):
            os_log(
                .info,
                "board setup with %s",
                command.player?.username ?? "unknown"
            )
            if let player = command.player {
                Task { @MainActor in
                    self.delegate?.manager(self, received: boardAction, from: player)
                }
            }
        case .addNode(let addNode):
            os_log(
                .info,
                "add node from %s using %@",
                command.player?.username ?? "unknown",
                String(describing: addNode)
            )
            if let player = command.player {
                Task { @MainActor in
                    await self.createHelicopter(addNodeAction: addNode, owner: player)
                }
            }
        case .completed(_):
            print("completed")
        }
    }
    
    // MARK: update
    // Called from rendering loop once per frame
    /// - Tag: GameManager-update
    func update(timeDelta: TimeInterval) {
        processCommandQueue()
        //       / syncMovement()
    }
    
    private func processCommandQueue() {
        // retrieving the command should happen with the lock held, but executing
        // it should be outside the lock.
        // inner function lets us take advantage of the defer keyword
        // for lock management.
        func nextCommand() -> GameCommand? {
            commandsLock.lock()
            defer {
                commandsLock.unlock()
            }
            if gameCommands.isEmpty {
                return nil
            } else {
                return gameCommands.removeFirst()
            }
        }
        while let command = nextCommand() {
            process(command: command)
        }
    }
    
    func start() {
        // Start advertising game
        if let session = session, session.isServer {
            session.startAdvertising()
        }
        movementSyncData.delegate = self
        Task { @MainActor in
            self.delegate?.managerDidStartGame(self)
        }
        isInitialized = true
    }
}
extension GameManager: NetworkSessionDelegate {
    nonisolated func networkSession(_ session: NetworkSession, received command: GameCommand) {
        // Extract safe, Sendable data
        let playerUsername = command.player?.username ?? ""
        let actionCopy = command.action
        
        Task { @MainActor in
            // Create new instances with safe data inside the main actor context
            let safePlayer = Player(username: playerUsername)
            let newCommand = GameCommand(
                player: safePlayer,
                action: actionCopy
            )
            if case .gameAction(.joyStickMoved) = actionCopy {
                self.commandsLock.withLock {
                    self.gameCommands.append(newCommand)
                }
            } else {
                self.process(command: newCommand)
            }
        }
    }
    
    nonisolated func networkSession(_ session: NetworkSession, joining player: Player) {
        let isHost = player == session.host
        let username = player.username
        Task { @MainActor in
            if isHost {
                self.delegate?.manager(self, joiningHost: Player(username: username))
            } else {
                self.delegate?.manager(self, joiningPlayer: Player(username: username))
            }
        }
    }
    
    nonisolated func networkSession(_ session: NetworkSession, leaving player: Player) {
        let isHost = player == session.host
        let safePlayer = Player(username: player.username) // Safe copy
        Task { @MainActor in
            // Remove helicopter when player leaves
            self.removeHelicopter(for: safePlayer)
            
            if isHost {
                self.delegate?.manager(self, leavingHost: safePlayer)
            } else {
                self.delegate?.manager(self, leavingPlayer: safePlayer)
            }
        }
    }
}


extension GameManager: MovementSyncSceneDataDelegate {
    nonisolated func hasNetworkDelayStatusChanged(hasNetworkDelay: Bool) {
        Task { @MainActor in
            self.delegate?.manager(
                self,
                hasNetworkDelay: hasNetworkDelay
            )
        }
    }
}

extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}
