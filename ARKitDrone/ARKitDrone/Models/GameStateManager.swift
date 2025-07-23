//
//  GameStateManager.swift
//  ARKitDrone
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import os.log

@MainActor
class GameStateManager {
    
    // MARK: - State Properties (No Combine - Better Performance)
    
    var sessionState: SessionState = SessionState.setup {
        didSet {
            if sessionState != oldValue {
                os_log(.info, "🎮 Game session state changed: %@ -> %@", oldValue.description, sessionState.description)
                Task { @MainActor in
                    await self.handleStateTransition(from: oldValue, to: self.sessionState)
                }
            }
        }
    }
    
    var helicopterPlaced: Bool = false {
        didSet {
            if helicopterPlaced != oldValue {
                os_log(.info, "🚁 Helicopter placed state: %@", helicopterPlaced ? "true" : "false")
            }
        }
    }
    
    var gameInProgress: Bool = false {
        didSet {
            if gameInProgress != oldValue {
                os_log(.info, "⚡ Game in progress: %@", gameInProgress ? "true" : "false")
            }
        }
    }
    
    var score: Int = 0 {
        didSet {
            if score != oldValue {
                // Async notification to prevent blocking
                Task { @MainActor in
                    NotificationCenter.default.post(name: .updateScore, object: nil)
                }
            }
        }
    }
    
    var missilesArmed: Bool = false {
        didSet {
            if missilesArmed != oldValue {
                os_log(.info, "🚀 Missiles armed: %@", missilesArmed ? "true" : "false")
            }
        }
    }
    
    var helicopterHealth: Float = 100.0 {
        didSet {
            // Only log significant health changes to reduce performance impact
            if helicopterHealth != oldValue && abs(helicopterHealth - oldValue) > 10.0 {
                os_log(.info, "💚 Helicopter health: %.1f -> %.1f", oldValue, helicopterHealth)
            }
        }
    }
    
    var helicopterAlive: Bool = true {
        didSet {
            if helicopterAlive != oldValue {
                os_log(.info, "💀 Helicopter alive: %@", helicopterAlive ? "true" : "false")
                if !helicopterAlive && gameInProgress {
                    // Only trigger game over if game is actually in progress
                    Task { @MainActor in
                        await self.handleGameOver()
                    }
                }
            }
        }
    }
    
    // MARK: - Game Configuration
    
    var isNetworked: Bool = false
    var isServer: Bool = false
    var connectedPlayers: Set<Player> = []
    
    // MARK: - UI State
    
    var controlsEnabled: Bool = true {
        didSet {
            if controlsEnabled != oldValue {
                os_log(.info, "🎮 Controls enabled: %@", controlsEnabled ? "true" : "false")
            }
        }
    }
    
    var overlayVisible: Bool = true
    var gameOverMessage: String = ""
    
    // MARK: - Game Statistics
    
    var shipsDestroyed: Int = 0 {
        didSet {
            if shipsDestroyed != oldValue {
                os_log(.info, "🛩️ Ships destroyed: %d", shipsDestroyed)
                Task { @MainActor in
                    await self.updateScore()
                }
            }
        }
    }
    
    var missilesFired: Int = 0
    var hits: Int = 0
    var accuracy: Float = 0.0
    
    // MARK: - State Validation
    
    private let validTransitions: [SessionState: Set<SessionState>] = [
        SessionState.setup: [SessionState.lookingForSurface, SessionState.waitingForBoard],
        SessionState.lookingForSurface: [SessionState.adjustingBoard, SessionState.placingBoard, SessionState.setup],
        SessionState.adjustingBoard: [SessionState.placingBoard, SessionState.lookingForSurface],
        SessionState.placingBoard: [SessionState.setupLevel, SessionState.lookingForSurface],
        SessionState.waitingForBoard: [SessionState.localizingToBoard, SessionState.setup],
        SessionState.localizingToBoard: [SessionState.setupLevel, SessionState.waitingForBoard],
        SessionState.setupLevel: [SessionState.gameInProgress],
        SessionState.gameInProgress: [SessionState.setup] // Allow restart
    ]
    
    // MARK: - Computed Properties
    
    var canPlaceHelicopter: Bool {
        return sessionState == SessionState.lookingForSurface && !helicopterPlaced
    }
    
    var canFireMissiles: Bool {
        return gameInProgress && helicopterPlaced && missilesArmed && helicopterAlive && controlsEnabled
    }
    
    var canMoveHelicopter: Bool {
        return helicopterPlaced && helicopterAlive && controlsEnabled
    }
    
    var gameOverState: Bool {
        return !helicopterAlive || sessionState == SessionState.setup
    }
    
    var scoreText: String {
        return "Score: \(score)"
    }
    
    var healthText: String {
        return "Health: \(Int(helicopterHealth))/100"
    }
    
    // MARK: - Initialization
    
    init() {
        os_log(.info, "🎮 GameStateManager initialized")
        setupInitialState()
    }
    
    private func setupInitialState() {
        // Initialize state synchronously to avoid async issues in init
        helicopterPlaced = false
        gameInProgress = false
        score = 0
        missilesArmed = false
        helicopterHealth = 100.0
        helicopterAlive = true
        controlsEnabled = true
        shipsDestroyed = 0
        missilesFired = 0
        hits = 0
        accuracy = 0.0
        gameOverMessage = ""
        
        os_log(.info, "🔄 Initial game state set")
    }
    
    // MARK: - State Transition Methods
    
    func transitionTo(_ newState: SessionState) {
        guard isValidTransition(from: sessionState, to: newState) else {
            os_log(.error, "❌ Invalid state transition: %@ -> %@", sessionState.description, newState.description)
            return
        }
        
        sessionState = newState
    }
    
    private func isValidTransition(from current: SessionState, to new: SessionState) -> Bool {
        return validTransitions[current]?.contains(new) ?? false
    }
    
    private func handleStateTransition(from oldState: SessionState, to newState: SessionState) async {
        switch newState {
        case SessionState.setup:
            await resetGameState()
            overlayVisible = true
            controlsEnabled = false
            
        case SessionState.lookingForSurface:
            controlsEnabled = false
            overlayVisible = false
            
        case SessionState.placingBoard, SessionState.adjustingBoard:
            controlsEnabled = false
            
        case SessionState.setupLevel:
            await prepareForGameplay()
            
        case SessionState.gameInProgress:
            await startGameplay()
            
        case SessionState.waitingForBoard, SessionState.localizingToBoard:
            controlsEnabled = false
        }
    }
    
    // MARK: - Game Lifecycle Methods
    
    func resetGameState() async {
        helicopterPlaced = false
        gameInProgress = false
        score = 0
        missilesArmed = false
        helicopterHealth = 100.0
        helicopterAlive = true
        controlsEnabled = true
        shipsDestroyed = 0
        missilesFired = 0
        hits = 0
        accuracy = 0.0
        gameOverMessage = ""
        
        os_log(.info, "🔄 Game state reset")
    }
    
    private func prepareForGameplay() async {
        controlsEnabled = true
        overlayVisible = false
        os_log(.info, "🎯 Preparing for gameplay")
        
        // Small delay to ensure smooth transition
        do {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        } catch {
            // Task cancelled, continue anyway
        }
    }
    
    private func startGameplay() async {
        gameInProgress = true
        controlsEnabled = true
        overlayVisible = false
        os_log(.info, "🚀 Gameplay started")
    }
    
    private func handleGameOver() async {
        gameInProgress = false
        controlsEnabled = false
        gameOverMessage = "HELICOPTER DESTROYED"
        
        os_log(.info, "💀 Game over - Final score: %d", score)
        
        // Async notification to avoid blocking
        await MainActor.run {
            NotificationCenter.default.post(
                name: .helicopterDestroyed,
                object: nil,
                userInfo: ["finalScore": score, "shipsDestroyed": shipsDestroyed]
            )
        }
    }
    
    // MARK: - Helicopter Management
    
    func placeHelicopter() {
        guard canPlaceHelicopter else {
            os_log(.error, "❌ Cannot place helicopter in current state")
            return
        }
        
        helicopterPlaced = true
        transitionTo(SessionState.setupLevel)
    }
    
    func updateHelicopterHealth(_ newHealth: Float) {
        helicopterHealth = max(0, min(100, newHealth))
        
        if helicopterHealth <= 0 && helicopterAlive {
            helicopterAlive = false
        }
    }
    
    func healHelicopter(_ amount: Float) {
        guard helicopterAlive else { return }
        updateHelicopterHealth(helicopterHealth + amount)
    }
    
    func damageHelicopter(_ damage: Float, from source: String = "unknown") {
        guard helicopterAlive else { return }
        
        os_log(.info, "💥 Helicopter taking %.1f damage from %@", damage, source)
        updateHelicopterHealth(helicopterHealth - damage)
    }
    
    // MARK: - Weapon Management
    
    func toggleMissileArmed() {
        guard helicopterPlaced && helicopterAlive else { return }
        missilesArmed.toggle()
    }
    
    func fireMissile() -> Bool {
        guard canFireMissiles else {
            os_log(.error, "⚠️ Cannot fire missile - conditions not met")
            return false
        }
        
        missilesFired += 1
        updateAccuracy()
        
        os_log(.info, "🚀 Missile fired - Total: %d", missilesFired)
        return true
    }
    
    func recordHit() {
        hits += 1
        updateAccuracy()
        os_log(.info, "🎯 Hit recorded - Total: %d", hits)
    }
    
    private func updateAccuracy() {
        accuracy = missilesFired > 0 ? Float(hits) / Float(missilesFired) * 100 : 0.0
    }
    
    // MARK: - Scoring System
    
    func destroyShip(worth points: Int = 100) {
        shipsDestroyed += 1
        score += points
        recordHit()
    }
    
    private func updateScore() async {
        // Base score calculation
        let baseScore = shipsDestroyed * 100
        
        // Accuracy bonus
        let accuracyBonus = Int(accuracy * Float(shipsDestroyed) / 10)
        
        // Health bonus (more health = higher multiplier)
        let healthBonus = Int(helicopterHealth / 100.0 * Float(shipsDestroyed) * 0.5)
        
        score = baseScore + accuracyBonus + healthBonus
    }
    
    // MARK: - Network State Management
    
    func setupNetworkedGame(asServer: Bool, connectedPlayers: Set<Player>) {
        self.isNetworked = true
        self.isServer = asServer
        self.connectedPlayers = connectedPlayers
        
        if asServer {
            transitionTo(SessionState.lookingForSurface)
        } else {
            transitionTo(SessionState.waitingForBoard)
        }
        
        os_log(.info, "🌐 Networked game setup - Server: %@, Players: %d", 
               asServer ? "true" : "false", connectedPlayers.count)
    }
    
    func addPlayer(_ player: Player) {
        connectedPlayers.insert(player)
        os_log(.info, "👤 Player added: %@", player.username)
    }
    
    func removePlayer(_ player: Player) {
        connectedPlayers.remove(player)
        os_log(.info, "👤 Player removed: %@", player.username)
    }
    
    // MARK: - Debug Methods
    
    func printCurrentState() {
        os_log(.debug, """
        🎮 GameStateManager Current State:
        - Session: %@
        - Helicopter Placed: %@
        - Game In Progress: %@
        - Score: %d
        - Health: %.1f
        - Missiles Armed: %@
        - Controls Enabled: %@
        - Ships Destroyed: %d
        - Accuracy: %.1f%%
        """, 
        sessionState.description,
        helicopterPlaced ? "true" : "false",
        gameInProgress ? "true" : "false",
        score,
        helicopterHealth,
        missilesArmed ? "true" : "false",
        controlsEnabled ? "true" : "false",
        shipsDestroyed,
        accuracy)
    }
}

