//
//  GameViewController+SCNPhysicsContactDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//
import UIKit

extension GameViewController {
    
    @objc func updateGameStateText() {
        destoryedText.text = game.destoryedTextString
        scoreText.text = game.scoreTextString
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.resetDestroyedText()
        }
    }
    
    func resetDestroyedText() {
        game.destoryedTextString = ""
        destoryedText.text = game.destoryedTextString
        destoryedText.fadeTransition(0.001)
    }
}

