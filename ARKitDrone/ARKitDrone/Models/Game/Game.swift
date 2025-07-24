//
//  Game.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

@MainActor
class Game {
    var playerScore: Int = 0 {
        didSet {
            if playerScore != oldValue {
                scoreUpdated = true
                updateScoreText()
            }
        }
    }
    var playerName: String!
    var playerWonGame: Bool = false
    var playerWonRound: Bool = false
    var currentLevel: Int = 0
    var enemiesLeft: Int = 0
    var scoreUpdated = false
    var placed: Bool = false
    var valueReached: Bool = false
    var destoryedTextString: String = ""
    var scoreTextString: String = ""
    
    // Reference to state manager for integration
    weak var stateManager: GameStateManager?
    
    // Computed property that syncs with state manager
    var score: Int {
        get { return stateManager?.score ?? playerScore }
        set {
            playerScore = newValue
            stateManager?.score = newValue
        }
    }
    
    func updateScoreText() {
        scoreTextString = "Score: \(self.playerScore)"
    }
    
    func setEnemyDestroyed() {
        destoryedTextString = "Enemy Destroyed!"
    }
    
    func reset() {
        playerScore = 0
        playerWonGame = false
        playerWonRound = false
        currentLevel = 0
        enemiesLeft = 0
        scoreUpdated = false
        placed = false
        valueReached = false
        destoryedTextString = ""
        scoreTextString = ""
        
        // Reset state manager if connected (async)
        if let stateManager = stateManager {
            Task { @MainActor in
                await stateManager.resetGameState()
            }
        }
    }
}
