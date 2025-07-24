//
//  GameManager.swift
//  ARKitDrone
//
//  Simplified game management system
//

import Foundation
import simd
import ARKit
import RealityKit

// MARK: - Simplified Game Manager

@MainActor
class GameManager: NSObject {
    
    // MARK: - Properties
    
    private var scene: RealityKit.Scene
    private let session: NetworkSession?
    private let entityManager = EntityManager()
    
    var helicopters = [Player: HelicopterObject]()
    let currentPlayer = UserDefaults.standard.myself
    
    let isNetworked: Bool
    let isServer: Bool
    
    weak var delegate: GameManagerDelegate?
    
    // MARK: - Initialization
    
    init(arView: ARView, session: NetworkSession?) {
        self.scene = arView.scene
        self.session = session
        self.isNetworked = session != nil
        self.isServer = session?.isServer ?? true
        super.init()
        
        self.session?.delegate = self
    }
    
    // MARK: - Scene Management
    
    func resetWorld(arView: ARView) {
        self.scene = arView.scene
    }
    
    // MARK: - Helicopter Management
    
    func createHelicopter(addNodeAction: AddNodeAction, owner: Player) async {
        // Offset the world transform upward slightly above the surface
        var modifiedTransform = addNodeAction.simdWorldTransform
        modifiedTransform.columns.3.y += 0.5
        
        // Create HelicopterObject instance
        let helicopterObject = await HelicopterObject(
            owner: owner,
            worldTransform: modifiedTransform
        )
        
        // Store and register
        helicopters[owner] = helicopterObject
        entityManager.register(helicopterObject)
        helicopterObject.addToScene(scene)
        
        // Notify delegate
        delegate?.manager(self, addNode: addNodeAction)
        delegate?.manager(self, createdHelicopter: helicopterObject, for: owner)
    }
    
    func moveHelicopter(player: Player, movement: MoveData) {
        guard let helicopter = helicopters[player] else { return }
        
        helicopter.updateMovement(moveData: movement)
        delegate?.manager(self, helicopterMovementUpdated: helicopter, for: player)
    }
    
    func switchHelicopterAnimation(player: Player, isMoving: Bool) {
        guard let helicopter = helicopters[player] else { return }
        
        helicopter.updateMovementState(isMoving: isMoving)
        
        // Send animation state to network if needed
        if isNetworked {
            if isMoving {
                send(gameAction: .helicopterStartMoving(true))
            } else {
                send(gameAction: .helicopterStopMoving(false))
            }
        }
    }
    
    func removeHelicopter(for player: Player) {
        guard let helicopter = helicopters[player] else { return }
        
        helicopter.removeFromScene()
        helicopters.removeValue(forKey: player)
        
        delegate?.manager(self, removedHelicopter: helicopter, for: player)
    }
    
    func getHelicopter(for player: Player) -> HelicopterObject? {
        return helicopters[player]
    }
    
    func getAllHelicopters() -> [HelicopterObject] {
        return Array(helicopters.values)
    }
    
    // MARK: - Network Communication
    
    func send(gameAction: GameAction) {
        session?.send(action: .gameAction(gameAction))
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
    
    // MARK: - Ship Synchronization
    
    func synchronizeShips(_ ships: [Ship]) {
        guard isNetworked && isServer else { return }
        
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
        
        send(gameAction: .shipsPositionSync(syncData))
    }
    
    func updateShipState(shipId: String, isDestroyed: Bool) {
        guard isNetworked else { return }
        send(gameAction: .shipDestroyed(shipId))
    }
    
    func updateShipTargeting(shipId: String, targeted: Bool) {
        guard isNetworked else { return }
        send(gameAction: .shipTargeted(shipId, targeted))
    }
    
    // MARK: - Missile Synchronization
    
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
    
    // MARK: - Update
    
    func update(timeDelta: TimeInterval) {
        entityManager.update(deltaTime: timeDelta)
    }
    
    // MARK: - Game Lifecycle
    
    func start() {
        if let session = session, session.isServer {
            session.startAdvertising()
        }
        
        delegate?.managerDidStartGame(self)
    }
    
    // MARK: - Network Message Processing
    
    private func processNetworkMessage(_ command: GameCommand) {
        guard let action = command.action as? Action else { return }
        
        switch action {
        case .gameAction(let gameAction):
            handleGameAction(gameAction, from: command.player)
        case .addNode(let addNode):
            if let player = command.player {
                Task {
                    await createHelicopter(addNodeAction: addNode, owner: player)
                }
            }
        case .boardSetup(let boardAction):
            if let player = command.player {
                delegate?.manager(self, received: boardAction, from: player)
            }
        default:
            break
        }
    }
    
    private func handleGameAction(_ gameAction: GameAction, from player: Player?) {
        guard let player = player else { return }
        
        switch gameAction {
        case .joyStickMoved(let data):
            moveHelicopter(player: player, movement: data)
            
        case .helicopterStartMoving(let isMoving):
            switchHelicopterAnimation(player: player, isMoving: isMoving)
            
        case .helicopterStopMoving(let isMoving):
            switchHelicopterAnimation(player: player, isMoving: !isMoving)
            
        case .shipsPositionSync(let ships):
            delegate?.manager(self, shipsUpdated: ships)
            
        case .shipDestroyed(let shipId):
            delegate?.manager(self, shipDestroyed: shipId)
            
        case .shipTargeted(let shipId, let targeted):
            delegate?.manager(self, shipTargeted: shipId, targeted: targeted)
            
        case .missileFired(let data):
            delegate?.manager(self, missileFired: data)
            
        case .missilePositionUpdate(let data):
            delegate?.manager(self, missilePositionUpdated: data)
            
        case .missileHit(let data):
            delegate?.manager(self, missileHit: data)
            
        default:
            break
        }
    }
}

// MARK: - Network Session Delegate

extension GameManager: NetworkSessionDelegate {
    nonisolated func networkSession(_ session: NetworkSession, received command: GameCommand) {
        let playerUsername = command.player?.username ?? ""
        let actionCopy = command.action
        
        Task { @MainActor in
            let safePlayer = Player(username: playerUsername)
            let newCommand = GameCommand(
                player: safePlayer,
                action: actionCopy
            )
            self.processNetworkMessage(newCommand)
        }
    }
    
    nonisolated func networkSession(_ session: NetworkSession, joining player: Player) {
        let isHost = player == session.host
        let username = player.username
        
        Task { @MainActor in
            let player = Player(username: username)
            if isHost {
                delegate?.manager(self, joiningHost: player)
            } else {
                delegate?.manager(self, joiningPlayer: player)
            }
        }
    }
    
    nonisolated func networkSession(_ session: NetworkSession, leaving player: Player) {
        let isHost = player == session.host
        let safePlayer = Player(username: player.username)
        
        Task { @MainActor in
            removeHelicopter(for: safePlayer)
            
            if isHost {
                delegate?.manager(self, leavingHost: safePlayer)
            } else {
                delegate?.manager(self, leavingPlayer: safePlayer)
            }
        }
    }
}

// MARK: - Movement Sync Delegate

extension GameManager: MovementSyncSceneDataDelegate {
    nonisolated func hasNetworkDelayStatusChanged(hasNetworkDelay: Bool) {
        Task { @MainActor in
            delegate?.manager(self, hasNetworkDelay: hasNetworkDelay)
        }
    }
}