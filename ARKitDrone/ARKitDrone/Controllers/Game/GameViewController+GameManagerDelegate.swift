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
        self.sessionState = .gameInProgress
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
                self.sessionState = .lookingForSurface
            case .manual:
                os_log(.info, "Received a manual board placement")
                self.sessionState = .lookingForSurface
            }
        case .requestBoardLocation:
            os_log(.info, "sending world to peer")
            self.sendWorldTo(peer: peer)
        }
    }
    
    func manager(_ manager: GameManager, addNode: AddNodeAction) {
        os_log(.info, "adding node")
        // Extract position from transform matrix
        let tappedPosition = SIMD3<Float>(
            addNode.simdWorldTransform.columns.3.x,
            addNode.simdWorldTransform.columns.3.y,
            addNode.simdWorldTransform.columns.3.z
        )
        
        Task { [weak self] in
            guard let self = self else { return }
            if let apache = await self.realityKitView.positionHelicopter(at: tappedPosition) {
                await MainActor.run {
                     self.realityKitView.competitor = apache // Commented out - competitor property removed
                    
                    // Create RealityKit target entity instead of SCN TargetNode
                    let targetEntity = TargetNode()
                    targetEntity.transform.translation = SIMD3<Float>(
                        tappedPosition.x,
                        tappedPosition.y + 1,
                        tappedPosition.z
                    )
                    
                    let anchor = AnchorEntity(world: targetEntity.transform.translation)
                    anchor.addChild(targetEntity)
                    self.realityKitView.scene.addAnchor(anchor)
                    
                    let endPos = SIMD3<Float>(
                        x: tappedPosition.x,
                        y: tappedPosition.y,
                        z: tappedPosition.z
                    )
                    self.gameManager?.send(
                        completed: CompletedAction.init(position: endPos)
                    )
                }
            }
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
            if self.sessionState == .waitingForBoard {
                manager.send(boardAction: .requestBoardLocation)
            }
            //guard !UserDefaults.standard.disableInGameUI else { return }
        }
    }
    
    func manager(_ manager: GameManager, leavingHost host: Player) { }
    
    func managerDidStartGame(_ manager: GameManager) {
        
    }
}
