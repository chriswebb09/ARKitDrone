//
//  GameStateManagerComprehensiveTests.swift
//  ARKitDroneTests
//
//  Comprehensive TDD-style tests for GameStateManager
//

import Testing
import RealityKit
@testable import ARKitDrone

@MainActor
struct GameStateManagerComprehensiveTests {
    
    var gameStateManager: GameStateManager!
    
    init() {
        gameStateManager = GameStateManager()
    }
    
    // MARK: - Initialization Tests
    
    @Test("GameStateManager initializes with correct default values")
    func testInitialization() {
        #expect(gameStateManager.sessionState == .setup)
        #expect(gameStateManager.helicopterPlaced == false)
        #expect(gameStateManager.gameInProgress == false) // Should be false initially
        #expect(gameStateManager.score == 0)
        #expect(gameStateManager.shipsDestroyed == 0)
        #expect(gameStateManager.helicopterHealth == 100.0)
        #expect(gameStateManager.helicopterAlive == true)
        #expect(gameStateManager.missilesArmed == false)
    }
    
    // MARK: - State Transition Tests
    
    @Test("Valid state transitions work correctly")
    func testValidStateTransitions() {
        let freshGameStateManager = GameStateManager()
        
        // Setup -> LookingForSurface
        freshGameStateManager.transitionTo(.lookingForSurface)
        #expect(freshGameStateManager.sessionState == .lookingForSurface)
        
        // LookingForSurface -> GameInProgress
        freshGameStateManager.transitionTo(.gameInProgress)
        #expect(freshGameStateManager.sessionState == .gameInProgress)
        #expect(freshGameStateManager.gameInProgress == true)
        
        // GameInProgress -> Setup (restart)
        freshGameStateManager.transitionTo(.setup)
        #expect(freshGameStateManager.sessionState == .setup)
        #expect(freshGameStateManager.gameInProgress == false)
    }
    
    @Test("Invalid state transitions are rejected")
    func testInvalidStateTransitions() {
        // Try invalid transition: Setup -> AdjustingBoard (not allowed)
        let initialState = gameStateManager.sessionState
        gameStateManager.transitionTo(.adjustingBoard)
        #expect(gameStateManager.sessionState == initialState) // Should remain unchanged
    }
    
    @Test("State transition from setup to gameInProgress sets correct properties")
    func testSetupToGameInProgressTransition() {
        gameStateManager.transitionTo(.gameInProgress)
        
        #expect(gameStateManager.sessionState == .gameInProgress)
        #expect(gameStateManager.gameInProgress == true)
        #expect(gameStateManager.controlsEnabled == true)
        #expect(gameStateManager.overlayVisible == false)
    }
    
    // MARK: - Helicopter Management Tests
    
    @Test("Helicopter placement updates state correctly")
    func testHelicopterPlacement() {
        let freshGameStateManager = GameStateManager()
        freshGameStateManager.transitionTo(.lookingForSurface) // Needed for canPlaceHelicopter
        
        #expect(freshGameStateManager.helicopterPlaced == false)
        #expect(freshGameStateManager.canPlaceHelicopter == true)
        
        freshGameStateManager.placeHelicopter()
        #expect(freshGameStateManager.helicopterPlaced == true)
    }
    
    @Test("Helicopter health management works correctly")
    func testHelicopterHealthManagement() {
        let initialHealth = gameStateManager.helicopterHealth
        #expect(initialHealth == 100.0)
        #expect(gameStateManager.helicopterAlive == true)
        
        // Update health
        gameStateManager.updateHelicopterHealth(75.0)
        #expect(gameStateManager.helicopterHealth == 75.0)
        #expect(gameStateManager.helicopterAlive == true)
        
        // Damage helicopter
        gameStateManager.damageHelicopter(50.0, from: "enemy")
        #expect(gameStateManager.helicopterHealth == 25.0)
        #expect(gameStateManager.helicopterAlive == true)
        
        // Destroy helicopter
        gameStateManager.damageHelicopter(30.0, from: "enemy")
        #expect(gameStateManager.helicopterHealth <= 0.0)
        #expect(gameStateManager.helicopterAlive == false)
    }
    
    @Test("Helicopter health cannot go negative")
    func testHelicopterHealthLimits() {
        gameStateManager.damageHelicopter(150.0, from: "enemy") // Massive damage
        #expect(gameStateManager.helicopterHealth >= 0.0)
        #expect(gameStateManager.helicopterAlive == false)
    }
    
    // MARK: - Scoring System Tests
    
    @Test("Ship destruction updates score correctly")
    func testShipDestructionScoring() {
        let initialScore = gameStateManager.score
        let initialShipsDestroyed = gameStateManager.shipsDestroyed
        
        gameStateManager.destroyShip(worth: 100)
        
        #expect(gameStateManager.score == initialScore + 100)
        #expect(gameStateManager.shipsDestroyed == initialShipsDestroyed + 1)
    }
    
    @Test("Multiple ship destructions accumulate score")
    func testMultipleShipDestructionScoring() {
        gameStateManager.destroyShip(worth: 100)
        gameStateManager.destroyShip(worth: 150)
        gameStateManager.destroyShip(worth: 75)
        
        #expect(gameStateManager.score == 325)
        #expect(gameStateManager.shipsDestroyed == 3)
    }
    
    @Test("Score never goes below zero")
    func testScoreNeverNegative() {
        gameStateManager.score = 50
        gameStateManager.destroyShip(worth: -100) // Negative scoring
        
        #expect(gameStateManager.score >= 0)
    }
    
    @Test("Zero value ship destruction still counts toward ships destroyed")
    func testZeroValueShipDestruction() {
        let initialShipsDestroyed = gameStateManager.shipsDestroyed
        
        gameStateManager.destroyShip(worth: 0)
        
        #expect(gameStateManager.shipsDestroyed == initialShipsDestroyed + 1)
    }
    
    // MARK: - Missile System Tests
    
    @Test("Missile arming state management")
    func testMissileArmingState() {
        let freshGameStateManager = GameStateManager()
        
        #expect(freshGameStateManager.missilesArmed == false)
        
        // Set up required conditions for missile arming
        freshGameStateManager.helicopterPlaced = true
        freshGameStateManager.helicopterAlive = true
        
        freshGameStateManager.toggleMissileArmed()
        #expect(freshGameStateManager.missilesArmed == true)
        
        freshGameStateManager.toggleMissileArmed()
        #expect(freshGameStateManager.missilesArmed == false)
    }
    
    @Test("Missile statistics are tracked correctly")
    func testMissileStatistics() {
        // Set up conditions for firing missiles
        gameStateManager.helicopterPlaced = true
        gameStateManager.helicopterAlive = true
        gameStateManager.missilesArmed = true
        gameStateManager.gameInProgress = true
        gameStateManager.controlsEnabled = true
        
        _ = gameStateManager.fireMissile()
        _ = gameStateManager.fireMissile()
        gameStateManager.recordHit()
        
        #expect(gameStateManager.missilesFired == 2)
        #expect(gameStateManager.hits == 1)
        #expect(abs(gameStateManager.accuracy - 50.0) < 0.1) // 50% accuracy (stored as percentage)
    }
    
    @Test("Accuracy calculation handles zero missiles fired")
    func testAccuracyWithZeroMissiles() {
        #expect(gameStateManager.missilesFired == 0)
        #expect(gameStateManager.accuracy == 0.0) // Should not crash with division by zero
    }
    
    // MARK: - Game Flow Tests
    
    @Test("Complete game flow from start to game over")
    func testCompleteGameFlow() {
        // 1. Initial state
        #expect(gameStateManager.sessionState == .setup)
        #expect(gameStateManager.gameInProgress == false)
        
        // 2. Start game
        gameStateManager.transitionTo(.lookingForSurface)
        #expect(gameStateManager.sessionState == .lookingForSurface)
        
        // 3. Place helicopter
        gameStateManager.placeHelicopter()
        #expect(gameStateManager.helicopterPlaced == true)
        
        // 4. Transition to gameplay
        gameStateManager.transitionTo(.gameInProgress)
        #expect(gameStateManager.gameInProgress == true)
        
        // 5. Play game (score some points)
        gameStateManager.destroyShip(worth: 100)
        gameStateManager.destroyShip(worth: 150)
        #expect(gameStateManager.score == 250)
        
        // 6. Take damage and survive
        gameStateManager.damageHelicopter(50.0, from: "enemy")
        #expect(gameStateManager.helicopterAlive == true)
        
        // 7. Game over (helicopter destroyed)
        gameStateManager.damageHelicopter(60.0, from: "enemy")
        #expect(gameStateManager.helicopterAlive == false)
        
        // 8. Reset for new game
        gameStateManager.transitionTo(.setup)
        #expect(gameStateManager.sessionState == .setup)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Rapid state transitions are handled correctly")
    func testRapidStateTransitions() {
        // Rapid valid transitions
        gameStateManager.transitionTo(.lookingForSurface)
        gameStateManager.transitionTo(.gameInProgress)
        gameStateManager.transitionTo(.setup)
        gameStateManager.transitionTo(.lookingForSurface)
        
        #expect(gameStateManager.sessionState == .lookingForSurface)
    }
    
    @Test("Invalid health values are handled gracefully")
    func testInvalidHealthValues() {
        // Test negative health update
        gameStateManager.updateHelicopterHealth(-50.0)
        #expect(gameStateManager.helicopterHealth >= 0.0)
        
        // Test excessive health update
        gameStateManager.updateHelicopterHealth(200.0)
        #expect(gameStateManager.helicopterHealth <= 100.0) // Should be capped at max
    }
    
    @Test("Concurrent score updates are handled correctly")
    func testConcurrentScoreUpdates() {
        // Simulate rapid score updates
        for i in 1...10 {
            gameStateManager.destroyShip(worth: i * 10)
        }
        
        let expectedScore = (1...10).reduce(0) { $0 + $1 * 10 } // Sum of 10+20+30+...+100
        #expect(gameStateManager.score == expectedScore)
        #expect(gameStateManager.shipsDestroyed == 10)
    }
    
    // MARK: - Property Dependency Tests
    
    @Test("Game state properties have correct dependencies")
    func testPropertyDependencies() {
        // When gameInProgress is true, helicopterPlaced should typically be true
        gameStateManager.helicopterPlaced = true
        gameStateManager.transitionTo(.gameInProgress)
        
        #expect(gameStateManager.gameInProgress == true)
        #expect(gameStateManager.helicopterPlaced == true)
    }
    
    @Test("State manager handles invalid property combinations gracefully")
    func testInvalidPropertyCombinations() {
        // Set contradictory states and ensure system handles gracefully
        gameStateManager.helicopterAlive = false
        gameStateManager.helicopterHealth = 100.0
        
        // System should handle this inconsistency
        #expect(gameStateManager.helicopterAlive == false) // Should maintain set value
    }
}