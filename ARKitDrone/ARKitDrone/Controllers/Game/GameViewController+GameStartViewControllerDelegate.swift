//
//  GameViewController+GameStartViewControllerDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/11/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//
import UIKit
import os.log

extension GameViewController: GameStartViewControllerDelegate {
    
    private func createGameManager(for session: NetworkSession?) {
        os_log(.info, "creating game manager")
        // First hide the overlay
        hideOverlay()
        // Create the game manager with proper session
        gameManager = GameManager(
            arView: realityKitView,
            session: session
        )
        gameManager?.start()
        // Setup views after manager is created
        DispatchQueue.main.async {
            self.setupViews()
        }
    }
    
    func gameStartViewController(_ _: UIViewController, didPressStartSoloGameButton: UIButton) {
        os_log(.info, "🎮 Starting solo game")
        // Create a solo session (no networking)
        let soloSession = NetworkSession(
            myself: UserDefaults.standard.myself,
            asServer: true,
            host: UserDefaults.standard.myself
        )
        createGameManager(for: soloSession)
    }
    
    func gameStartViewController(_ _: UIViewController, didStart game: NetworkSession) {
        os_log(.info, "did start game")
        hideOverlay()
        createGameManager(for: game)
    }
    
    func gameStartViewController(_ _: UIViewController, didSelect game: NetworkSession) {
        os_log(.info, "did select game")
        hideOverlay()
        createGameManager(for: game)
    }
}
