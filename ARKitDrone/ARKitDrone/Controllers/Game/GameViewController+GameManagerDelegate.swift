//
//  GameViewController+GameManagerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/11/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import os.log
import SceneKit

extension GameViewController: GameManagerDelegate {
    
    func manager(_ manager: GameManager, hasNetworkDelay: Bool) { }
    
    func manager(_ manager: GameManager, moveNode: MoveData) {
        os_log(.info, "move forward from joytick %s", String.init(describing: moveNode))
        DispatchQueue.main.async {
            if let dir = moveNode.direction {
                switch dir {
                case .forward:
                    self.sceneView.competitor.moveForward(value: (moveNode.velocity.vector.y))
                case .altitude:
                    self.sceneView.competitor.changeAltitude(value: moveNode.velocity.vector.y)
                case .rotation:
                    self.sceneView.competitor.rotate(value: moveNode.velocity.vector.x)
                case .side:
                    self.sceneView.competitor.moveSides(value: moveNode.velocity.vector.x)
                }
            } else {
                self.sceneView.competitor.moveForward(value: moveNode.velocity.vector.y)
            }
        }
    }
    
    func manager(_ manager: GameManager, completed: CompletedAction) {
        print("completed")
        sessionState = .gameInProgress
    }
    
    private func process(boardAction: BoardSetupAction, from peer: Player) {
        os_log(.info, "board setup action from %s", peer.username)
        switch boardAction {
        case .boardLocation(let location):
            os_log(.info, "board location")
            switch location {
            case .worldMapData(let data):
                os_log(.info, "Received WorldMap data. Size: %d", data.count)
                loadWorldMap(from: data)
                sessionState = .lookingForSurface
            case .manual:
                os_log(.info, "Received a manual board placement")
                sessionState = .lookingForSurface
            }
        case .requestBoardLocation:
            os_log(.info, "sending world to peer")
            sendWorldTo(peer: peer)
        }
    }
    
    func manager(_ manager: GameManager, addNode: AddNodeAction) {
        os_log(.info, "adding node")
        let tappedPosition = SCNVector3.positionFromTransform(addNode.simdWorldTransform)
        DispatchQueue.main.async {
            let apache: ApacheHelicopter = self.sceneView.positionHelicopter(position: tappedPosition)
            let square = TargetNode()
            self.sceneView.scene.rootNode.addChildNode(square)
            self.sceneView.competitor = apache
            square.simdScale = [1.0, 1.0, 1.0]
            square.unhide()
            square.displayNodeHierarchyOnTop(true)
            square.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.01
            square.position = SCNVector3(x: apache.helicopterNode.position.x, y: apache.helicopterNode.position.y + 1, z: apache.helicopterNode.position.z)
            SCNTransaction.commit()
            let endPos = SIMD3<Float>(x: tappedPosition.x, y: tappedPosition.y, z: tappedPosition.z)
            self.gameManager?.send(completed:CompletedAction.init(position: endPos))
        }
    }
    
    func manager(_ manager: GameManager, received boardAction: BoardSetupAction, from player: Player) {
        os_log(.info, "received action to process %s", String(describing: boardAction))
        DispatchQueue.main.async {
            self.process(boardAction: boardAction, from: player)
        }
    }
    
    func manager(_ manager: GameManager, joiningPlayer player: Player) { }
    
    func manager(_ manager: GameManager, leavingPlayer player: Player) { }
    
    func manager(_ manager: GameManager, joiningHost host: Player) {
        os_log(.info, "GameManagerDelegate joining host")
        // MARK: request worldmap when joining the host
        DispatchQueue.main.async {
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
