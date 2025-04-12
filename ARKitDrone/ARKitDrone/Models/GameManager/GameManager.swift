//
//  GameManager.swift
//  Multiplayer_test
//
//  Created by Shawn Ma on 9/29/18.
//  Copyright © 2018 Shawn Ma. All rights reserved.
//

import Foundation
import SceneKit
import GameplayKit
import simd
import ARKit
import AVFoundation
import os.signpost

/// - Tag: GameManager
class GameManager: NSObject {
    // don't execute any code from SCNView renderer until this is true
    private(set) var isInitialized = false
    
    private let session: NetworkSession?
    private var scene: SCNScene
    
    var tanks = Set<GameObject>()
    
    private let catapultsLock = NSLock()
    private var gameCommands = [GameCommand]()
    private let commandsLock = NSLock()
    
    private let movementSyncData = MovementSyncSceneData()
    
    let currentPlayer = UserDefaults.standard.myself
    
    let isNetworked: Bool
    let isServer: Bool
    
    init(sceneView: SCNView, session: NetworkSession?) {
        self.scene = sceneView.scene!
        self.session = session
        
        self.isNetworked = session != nil
        self.isServer = session?.isServer ?? true // Solo game act like a server
        
        super.init()
        
        self.session?.delegate = self
    }
    
    func queueAction(gameAction: GameAction) {
        commandsLock.lock()
        defer { commandsLock.unlock() }
        gameCommands.append(GameCommand(player: currentPlayer, action: .gameAction(gameAction)))
    }
    
    private func syncMovement() {
        os_signpost(.begin, log: .render_loop, name: .physics_sync, signpostID: .render_loop,
                    "Movement sync started")
        defer { os_signpost(.end, log: .render_loop, name: .physics_sync, signpostID: .render_loop,
                            "Movement sync finished") }
        
        if isNetworked && movementSyncData.isInitialized {
            if isServer {
                let movementData = movementSyncData.generateData()
                session?.send(action:
                        .gameAction(
                            .movement(movementData)
                        )
                )
            } else {
                movementSyncData.updateFromReceivedData()
            }
        }
    }
    
    
    func resetWorld(sceneView: SCNView) {
        self.scene = sceneView.scene!
    }
    
    weak var delegate: GameManagerDelegate?
    
    func send(gameAction: GameAction) {
        session?.send(action: .gameAction(gameAction))
    }
    
    func send(completed: CompletedAction) {
        session?.send(action: .completed(completed))
    }
    
    func send(addNode: AddNodeAction) {
        session?.send(action: .addNode(addNode))
    }
    
    func send(boardAction: BoardSetupAction) {
        session?.send(action: .boardSetup(boardAction))
    }
    
    func send(boardAction: BoardSetupAction, to player: Player) {
        session?.send(action: .boardSetup(boardAction), to: player)
    }
    
    // MARK: - inbound from network
    private func process(command: GameCommand) {
        os_signpost(.begin, log: .render_loop, name: .process_command, signpostID: .render_loop,
                    "Action End : %s", command.action.description)
        defer { os_signpost(.end, log: .render_loop, name: .process_command, signpostID: .render_loop,
                            "Action End: %s", command.action.description) }
        
        switch command.action {
        case .gameAction(let gameAction):
            os_log(.info, "game action from %s for %s", command.player?.username ?? "unknown", String(describing: gameAction))
            // should controll tank here
            
            guard let player = command.player else { return }
            
            if case let .joyStickMoved(data) = gameAction {
                DispatchQueue.main.async {
                    self.delegate?.manager(self, moveNode: data)
                }
            }
            
//            if case let .movement(movementSyncData) = gameAction {
//                self.delegate?.manager(self, received: movementSyncData, from: player)
//            }
        case .boardSetup(let boardAction):
            os_log(.info, "board setup with %s", command.player?.username ?? "unknown")
            if let player = command.player {
                delegate?.manager(self, received: boardAction, from: player)
            }
        case .addNode(let addNode):
            os_log(.info, "add node from %s using %@", command.player?.username ?? "unknown", String(describing: addNode))
            if let player = command.player {
                DispatchQueue.main.async {
                    self.delegate?.manager(self, addNode: addNode)
                }
            }
        case .completed(let completed):
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
        delegate?.managerDidStartGame(self)
        isInitialized = true
    }
    
    func moveTank(player: Player, movement: MoveData, sceneView: GameSceneView? = nil) {
        os_log(.info, "move Tank")
        DispatchQueue.main.async {
            if let sceneView = sceneView {
                let x = sceneView.competitor.helicopterNode.position.x + movement.velocity.vector.x
                let y = sceneView.competitor.helicopterNode.position.y + movement.velocity.vector.y
                let z = sceneView.competitor.helicopterNode.position.z + movement.velocity.vector.y
                sceneView.competitor.helicopterNode.position = SCNVector3(x: x, y: y, z: z)
                sceneView.competitor.helicopterNode.eulerAngles.y = movement.angular
            }
        }
        
    }
}
extension GameManager: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received command: GameCommand) {
        commandsLock.lock()
        defer {
            commandsLock.unlock()
        }
        if case Action.gameAction(.joyStickMoved(_)) = command.action {
            gameCommands.append(command)
        } else {
            process(command: command)
        }
    }
    
    func networkSession(_ session: NetworkSession, joining player: Player) {
        if player == session.host {
            delegate?.manager(self, joiningHost: player)
        } else {
            delegate?.manager(self, joiningPlayer: player)
        }
    }
    
    func networkSession(_ session: NetworkSession, leaving player: Player) {
        if player == session.host {
            delegate?.manager(self, leavingHost: player)
        } else {
            delegate?.manager(self, leavingPlayer: player)
        }
    }
    
}


extension GameManager: MovementSyncSceneDataDelegate {
    func hasNetworkDelayStatusChanged(hasNetworkDelay: Bool) {
        delegate?.manager(self, hasNetworkDelay: hasNetworkDelay)
    }
    
}
