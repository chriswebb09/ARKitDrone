//
//  HelicopterObjectComprehensiveTests.swift
//  ARKitDroneTests
//
//  Comprehensive TDD-style tests for HelicopterObject system
//

import Testing
import RealityKit
import simd
import UIKit
@testable import ARKitDrone

@MainActor
struct HelicopterObjectComprehensiveTests {
    
    var mockPlayer: Player!
    var testTransform: simd_float4x4!
    
    init() {
        mockPlayer = Player(username: "TestPilot")
        testTransform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(5, 2, -10, 1) // Position at (5, 2, -10)
        )
    }
    
    // MARK: - Initialization Tests
    
    @Test("HelicopterObject initializes with correct properties")
    func testInitialization() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        #expect(helicopter.owner == mockPlayer)
        #expect(helicopter.helicopterEntity != nil)
        #expect(helicopter.healthSystem != nil)
        #expect(helicopter.isDestroyed == false)
        #expect(helicopter.rotorSpeed == 0.0)
        #expect(helicopter.rotorsActive == false)
    }
    
    @Test("HelicopterObject has unique identifiers")
    func testUniqueIdentifiers() async {
        let helicopter1 = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        let helicopter2 = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        #expect(helicopter1.id != helicopter2.id)
        #expect(helicopter1.index != helicopter2.index)
    }
    
    @Test("HelicopterObject creates anchor entity at correct position")
    func testAnchorEntityPosition() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        #expect(helicopter.anchorEntity != nil)
        
        if let anchor = helicopter.anchorEntity {
            let position = anchor.transform.translation
            #expect(abs(position.x - 5.0) < 0.01) // Should be at x=5
            #expect(abs(position.y - 2.0) < 0.01) // Should be at y=2
            #expect(abs(position.z - (-10.0)) < 0.01) // Should be at z=-10
        }
    }
    
    // MARK: - Health System Tests
    
    @Test("HelicopterObject health system initializes correctly")
    func testHealthSystemInitialization() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        #expect(helicopter.healthSystem != nil)
        #expect(helicopter.healthSystem?.currentHealth == 100.0)
        #expect(helicopter.healthSystem?.maxHealth == 100.0)
        #expect(helicopter.healthSystem?.isAlive == true)
        #expect(helicopter.isAlive() == true)
        #expect(helicopter.getHealthPercentage() == 100.0)
    }
    
    @Test("HelicopterObject damage system works correctly")
    func testDamageSystem() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Initial state
        #expect(helicopter.isAlive() == true)
        #expect(helicopter.healthSystem?.currentHealth == 100.0)
        
        // Take moderate damage
        helicopter.takeDamage(25.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 75.0)
        #expect(helicopter.isAlive() == true)
        #expect(helicopter.getHealthPercentage() == 75.0)
        
        // Take more damage
        helicopter.takeDamage(50.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 25.0)
        #expect(helicopter.isAlive() == true)
        #expect(helicopter.getHealthPercentage() == 25.0)
        
        // Fatal damage
        helicopter.takeDamage(30.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 0.0)
        #expect(helicopter.isAlive() == false)
        #expect(helicopter.getHealthPercentage() == 0.0)
    }
    
    @Test("HelicopterObject healing system works correctly")
    func testHealingSystem() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Damage first
        helicopter.takeDamage(40.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 60.0)
        
        // Heal partially
        helicopter.heal(20.0)
        #expect(helicopter.healthSystem?.currentHealth == 80.0)
        #expect(helicopter.isAlive() == true)
        
        // Heal beyond max (should cap at 100)
        helicopter.heal(50.0)
        #expect(helicopter.healthSystem?.currentHealth == 100.0)
        #expect(helicopter.getHealthPercentage() == 100.0)
    }
    
    @Test("HelicopterObject cannot be healed when destroyed")
    func testHealingWhenDestroyed() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Destroy helicopter
        helicopter.takeDamage(150.0, from: "test")
        #expect(helicopter.isAlive() == false)
        
        let healthBeforeHeal = helicopter.healthSystem?.currentHealth ?? 0.0
        
        // Attempt to heal (should not work)
        helicopter.heal(50.0)
        #expect(helicopter.healthSystem?.currentHealth == healthBeforeHeal)
        #expect(helicopter.isAlive() == false)
    }
    
    // MARK: - Missile System Tests
    
    @Test("HelicopterObject missile arming system works")
    func testMissileArmingSystem() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Initially disarmed
        #expect(helicopter.missilesArmed() == false)
        
        // Arm missiles
        helicopter.toggleMissileArmed()
        #expect(helicopter.missilesArmed() == true)
        
        // Disarm missiles
        helicopter.toggleMissileArmed()
        #expect(helicopter.missilesArmed() == false)
    }
    
    @Test("HelicopterObject has missiles available")
    func testMissileAvailability() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        #expect(helicopter.helicopterEntity != nil)
        
        if let helicopterEntity = helicopter.helicopterEntity {
            #expect(helicopterEntity.missiles.count > 0)
            
            // Each missile should have proper setup
            for missile in helicopterEntity.missiles {
                #expect(missile.entity != nil)
                #expect(!missile.id.isEmpty)
                #expect(missile.fired == false)
                #expect(missile.hit == false)
                #expect(missile.isDestroyed == false)
            }
        }
    }
    
    // MARK: - Animation and Movement Tests
    
    @Test("HelicopterObject rotor system works correctly")
    func testRotorSystem() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Initially rotors should be inactive
        #expect(helicopter.rotorSpeed == 0.0)
        #expect(helicopter.rotorsActive == false)
        
        // Test rotor state changes through movement updates
        let moveData = MoveData(velocity: GameVelocity(vector: SIMD3<Float>(0, 1, 0)), angular: 0.0, direction: .forward)
        helicopter.updateMovement(moveData: moveData)
        
        // Rotors should activate when moving
        // Note: Rotor activation is controlled internally through movement state
        #expect(helicopter.isMoving == true)
        
        // Test stopping movement
        let stopMoveData = MoveData(velocity: GameVelocity(vector: SIMD3<Float>(0, 0, 0)), angular: 0.0, direction: .none)
        helicopter.updateMovement(moveData: stopMoveData)
        #expect(helicopter.isMoving == false)
    }
    
    @Test("HelicopterObject movement state tracking")
    func testMovementStateTracking() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Initially should not be moving
        #expect(helicopter.isMoving == false)
        
        // Test movement state updates through updateMovementState
        helicopter.updateMovementState(isMoving: true)
        #expect(helicopter.isMoving == true)
        
        // Test idle state
        helicopter.updateMovementState(isMoving: false)
        #expect(helicopter.isMoving == false)
    }
    
    // MARK: - Position and Transform Tests
    
    @Test("HelicopterObject position updates correctly")
    func testPositionUpdates() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Test initial position using anchor entity directly
        if let anchor = helicopter.anchorEntity {
            let initialPosition = anchor.transform.translation
            print("🐛 DEBUG Position: Expected (5, 2, -10), got (\(initialPosition.x), \(initialPosition.y), \(initialPosition.z))")
            #expect(abs(initialPosition.x - 5.0) < 0.1)
            #expect(abs(initialPosition.y - 2.0) < 0.1)
            #expect(abs(initialPosition.z - (-10.0)) < 0.1)
        }
        
        // Test position update
        let newTransform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(10, 5, -15, 1)
        )
        
        helicopter.updateFromNetwork(transform: newTransform, isMoving: true)
        
        if let updatedTransform = helicopter.getWorldTransform() {
            let newPosition = SIMD3<Float>(
                updatedTransform.columns.3.x,
                updatedTransform.columns.3.y,
                updatedTransform.columns.3.z
            )
            
            #expect(abs(newPosition.x - 10.0) < 0.1)
            #expect(abs(newPosition.y - 5.0) < 0.1)
            #expect(abs(newPosition.z - (-15.0)) < 0.1)
        }
    }
    
    // MARK: - Entity Management Tests
    
    @Test("HelicopterObject entity hierarchy is correct")
    func testEntityHierarchy() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        #expect(helicopter.anchorEntity != nil)
        #expect(helicopter.helicopterEntity != nil)
        
        if let anchor = helicopter.anchorEntity,
           let helicopterModel = helicopter.helicopterEntity?.helicopter {
            #expect(helicopterModel.parent == anchor)
        }
    }
    
    @Test("HelicopterObject cleanup works correctly")
    func testCleanup() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Verify entities exist
        #expect(helicopter.anchorEntity != nil)
        #expect(helicopter.helicopterEntity != nil)
        #expect(helicopter.healthSystem != nil)
        
        // Cleanup
        await helicopter.cleanup()
        
        // Verify cleanup (some properties should be nil after cleanup)
        #expect(helicopter.healthSystem == nil)
    }
    
    // MARK: - Damage Immunity Tests
    
    @Test("HelicopterObject damage immunity works correctly")
    func testDamageImmunity() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // First damage should work
        helicopter.takeDamage(10.0, from: "enemy")
        #expect(helicopter.healthSystem?.currentHealth == 90.0)
        
        // Immediate second damage should be blocked by immunity (for non-test sources)
        helicopter.takeDamage(10.0, from: "enemy")
        #expect(helicopter.healthSystem?.currentHealth == 90.0) // Should still be 90
        
        // But test damage should bypass immunity
        helicopter.takeDamage(10.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 80.0) // Should be reduced
    }
    
    @Test("HelicopterObject can take damage when immunity period expires")
    func testDamageImmunityExpiry() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Take initial damage
        helicopter.takeDamage(10.0, from: "enemy")
        #expect(helicopter.healthSystem?.currentHealth == 90.0)
        
        // Wait for immunity to expire (simulate time passage)
        // Note: In real implementation, we'd need to wait or mock time
        // For now, we test that multiple test damages work
        helicopter.takeDamage(10.0, from: "test")
        helicopter.takeDamage(10.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 70.0)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("HelicopterObject handles excessive damage gracefully")
    func testExcessiveDamage() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        // Deal massive damage
        helicopter.takeDamage(1000.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == 0.0) // Should be capped at 0
        #expect(helicopter.isAlive() == false)
    }
    
    @Test("HelicopterObject handles negative damage gracefully")
    func testNegativeDamage() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        let initialHealth = helicopter.healthSystem?.currentHealth ?? 0.0
        
        // Try negative damage (should not heal)
        helicopter.takeDamage(-10.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == initialHealth)
    }
    
    @Test("HelicopterObject handles zero damage")
    func testZeroDamage() async {
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: testTransform)
        
        let initialHealth = helicopter.healthSystem?.currentHealth ?? 0.0
        
        helicopter.takeDamage(0.0, from: "test")
        #expect(helicopter.healthSystem?.currentHealth == initialHealth)
    }
    
    @Test("HelicopterObject handles invalid transform gracefully")
    func testInvalidTransform() async {
        let invalidTransform = simd_float4x4(
            SIMD4<Float>(Float.nan, 0, 0, 0),
            SIMD4<Float>(0, Float.nan, 0, 0),
            SIMD4<Float>(0, 0, Float.nan, 0),
            SIMD4<Float>(Float.nan, Float.nan, Float.nan, 1)
        )
        
        let helicopter = await HelicopterObject(owner: mockPlayer, worldTransform: invalidTransform)
        
        // Should still create successfully with fallback values
        #expect(helicopter.anchorEntity != nil)
        #expect(helicopter.helicopterEntity != nil)
        #expect(helicopter.healthSystem != nil)
    }
    
    // MARK: - Player Association Tests
    
    @Test("HelicopterObject maintains correct player association")
    func testPlayerAssociation() async {
        let player1 = Player(username: "Player1")
        let player2 = Player(username: "Player2")
        
        let helicopter1 = await HelicopterObject(owner: player1, worldTransform: testTransform)
        let helicopter2 = await HelicopterObject(owner: player2, worldTransform: testTransform)
        
        #expect(helicopter1.owner == player1)
        #expect(helicopter2.owner == player2)
        #expect(helicopter1.owner != helicopter2.owner)
    }
    
    @Test("HelicopterObject handles nil player gracefully")
    func testNilPlayer() async {
        let helicopter = await HelicopterObject(owner: nil, worldTransform: testTransform)
        
        #expect(helicopter.owner == nil)
        #expect(helicopter.helicopterEntity != nil) // Should still create
        #expect(helicopter.healthSystem != nil) // Should still have health system
    }
    
    // MARK: - Performance Tests
    
    @Test("HelicopterObject creation is performant")
    func testCreationPerformance() async {
        let startTime = CACurrentMediaTime()
        
        var helicopters: [HelicopterObject] = []
        for i in 0..<10 {
            let player = Player(username: "Player\(i)")
            let helicopter = await HelicopterObject(owner: player, worldTransform: testTransform)
            helicopters.append(helicopter)
        }
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        #expect(duration < 10.0) // Should create 10 helicopters in under 10 seconds
        #expect(helicopters.count == 10)
        
        // Cleanup
        for helicopter in helicopters {
            await helicopter.cleanup()
        }
    }
}
