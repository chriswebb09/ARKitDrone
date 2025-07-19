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
class GameManager: NSObject, @unchecked Sendable {
    // don't execute any code from SCNView renderer until this is true
    private(set) var isInitialized = false
    
    private let session: NetworkSession?
    private var scene: RealityKit.Scene
    
    var tanks = Set<GameObject>()
    
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
            _ = command.player
            if case let .joyStickMoved(data) = gameAction {
                Task { @MainActor in
                    self.delegate?.manager(self, moveNode: data)
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
            if command.player != nil {
                Task { @MainActor in
                    self.delegate?.manager(self, addNode: addNode)
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
            let newCommand = GameCommand(player: safePlayer, action: actionCopy)
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
            self.delegate?.manager(self, hasNetworkDelay: hasNetworkDelay)
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
