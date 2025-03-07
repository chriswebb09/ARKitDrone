//
//  Game.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit

class Game {
    var playerScore: Int = 0
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
    
    func updateScoreText() {
        destoryedTextString = "Enemy Destroyed!"
        scoreTextString = "Score: \(self.playerScore)"
    }
}
