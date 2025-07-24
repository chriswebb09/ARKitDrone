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
        
        // Update MissileManager with the new GameManager reference
        missileManager?.gameManager = gameManager
        
        // Views are already setup in viewDidAppear
    }
    
    func gameStartViewController(_ _: UIViewController, didPressStartSoloGameButton: UIButton) {
        os_log(.info, "🎮 Starting solo game")
        // Solo game has no network session
        createGameManager(for: nil)
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
