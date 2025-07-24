//
//  HelicopterObject.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import ARKit
import simd
import os.log

/// Each helicopter belongs to a specific player and syncs across all clients
@MainActor
class HelicopterObject: GameEntity {
    
    // MARK: - Core Properties (matching GameObject pattern)
    
    /// The player who owns this helicopter
    var owner: Player?
    
    /// Unique identifier for this helicopter across all players
    nonisolated let index: Int
    
    /// Global counter for helicopter IDs
    static var indexCounter = 0
    
    /// Whether this helicopter is currently moving (for animation sync)
    var isMoving: Bool = false
    
    /// The main helicopter entity in the scene
    var helicopterEntity: ApacheHelicopter?
    
    /// The anchor entity that holds the helicopter in AR space
    var anchorEntity: AnchorEntity?
    
    /// Health system for this helicopter
    var healthSystem: HelicopterHealthSystem?
    
    /// Cached reference to the anchor entity for nonisolated access
    private var _cachedAnchorEntity: Entity?
    
    // MARK: - GameEntity Protocol Properties
    
    /// Unique identifier for EntityManager
    nonisolated var id: String {
        return "helicopter_\(index)"
    }
    
    /// The main RealityKit entity for this helicopter  
    @MainActor var entity: Entity {
        // For EntityManager compatibility, return the cached anchor entity
        // The anchor entity is the root entity in the AR scene hierarchy
        return _cachedAnchorEntity ?? Entity()
    }
    
    /// Whether this helicopter is destroyed
    var isDestroyed: Bool = false
    
    // MARK: - Animation Properties
    
    /// Current rotor speed (0.0 = stopped, 1.0 = max speed)
    var rotorSpeed: Float = 0.0
    
    /// Whether rotors are currently spinning
    var rotorsActive: Bool = false
    
    /// Target rotor speed for smooth transitions
    private var targetRotorSpeed: Float = 0.0
    
    /// Timer for smooth rotor speed interpolation
    private var animationTimer: Timer?
    
    // MARK: - Simplified Properties
    
    /// Whether this helicopter is owned by the local player
    var isLocalPlayer: Bool {
        guard let owner = owner else { return false }
        return owner == UserDefaults.standard.myself
    }
    
    // MARK: - Initialization
    
    init(owner: Player?, index: Int? = nil, worldTransform: simd_float4x4) async {
        self.owner = owner
        
        if let index = index {
            self.index = index
        } else {
            self.index = HelicopterObject.indexCounter
            HelicopterObject.indexCounter += 1
        }
        
        os_log(.info, "Creating HelicopterObject for player %s with index %d", 
               owner?.username ?? "unknown", self.index)
        
        await setupHelicopter(at: worldTransform)
    }
    
    // MARK: - Helicopter Setup
    
    private func setupHelicopter(at worldTransform: simd_float4x4) async {
        // Create anchor entity at the specified world position
        let translation = SIMD3<Float>(
            worldTransform.columns.3.x,
            worldTransform.columns.3.y,
            worldTransform.columns.3.z
        )
        
        anchorEntity = AnchorEntity(world: translation)
        // Ensure the anchor's transform matches our expected position
        anchorEntity?.transform.translation = translation
        _cachedAnchorEntity = anchorEntity
        
        // Create helicopter instance
        helicopterEntity = await ApacheHelicopter()
        
        // Initialize health system (always initialize regardless of helicopter entity state)
        healthSystem = HelicopterHealthSystem(maxHealth: 100.0)
        setupHealthSystemCallbacks()
        
        // Add helicopter to anchor
        if let helicopter = helicopterEntity?.helicopter,
           let anchor = anchorEntity {
            anchor.addChild(helicopter)
            os_log(.info, "Helicopter entity added to anchor for player %s", owner?.username ?? "unknown")
        } 
        
        os_log(.info, "Helicopter setup complete for player %s", owner?.username ?? "unknown")
    }
    
    // MARK: - Health System Setup
    
    private func setupHealthSystemCallbacks() {
        guard let healthSystem = healthSystem else { return }
        
        healthSystem.onHealthChanged = { [weak self] currentHealth, maxHealth in
            let percentage = (currentHealth / maxHealth) * 100
            print("🏥 Helicopter \(self?.index ?? -1) health: \(Int(currentHealth))/\(Int(maxHealth)) (\(Int(percentage))%)")
            
            // Post notification for UI updates (only for local player)
            if let owner = self?.owner, owner == UserDefaults.standard.myself {
                NotificationCenter.default.post(
                    name: .helicopterHealthChanged,
                    object: nil,
                    userInfo: ["currentHealth": currentHealth, "maxHealth": maxHealth]
                )
            }
        }
        
        healthSystem.onDamageTaken = { [weak self] damage in
            print("💥 Helicopter \(self?.index ?? -1) took \(damage) damage")
            // Could trigger screen shake or other effects here
        }
        
        healthSystem.onCriticalHealth = { [weak self] in
            print("🚨 Helicopter \(self?.index ?? -1) is in critical condition!")
            // Could trigger warning sounds or red screen overlay
        }
        
        healthSystem.onHelicopterDestroyed = { [weak self] in
            print("💀 Helicopter \(self?.index ?? -1) has been destroyed!")
            // Could trigger game over or respawn logic
        }
    }
    
    // MARK: - Movement Methods
    
    /// Update helicopter position from network or local input (simplified)
    func updateMovement(moveData: MoveData) {
        guard let helicopter = helicopterEntity else { return }
        
        let speed: Float = 0.008
        switch moveData.direction {
        case .forward:
            helicopter.moveForward(value: moveData.velocity.vector.y * speed)
        case .side:
            helicopter.moveSides(value: moveData.velocity.vector.x * speed)
        case .altitude:
            helicopter.changeAltitude(value: moveData.velocity.vector.y * speed)
        case .rotation:
            helicopter.rotate(yaw: moveData.velocity.vector.x * speed)
        case .none:
            helicopter.moveForward(value: moveData.velocity.vector.y * speed)
        @unknown default:
            break
        }
        
        // Update animation state
        let hasMovement = simd_length(moveData.velocity.vector) > 0.001
        updateMovementState(isMoving: hasMovement)
    }
    
    /// Set position directly (for network synchronization)
    func setWorldTransform(_ transform: simd_float4x4) {
        guard let anchor = anchorEntity else { return }
        
        let translation = SIMD3<Float>(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
        let rotationMatrix = simd_float3x3(transform.columns.0.xyz, transform.columns.1.xyz, transform.columns.2.xyz)
        let rotation = simd_quatf(rotationMatrix)
        
        anchor.transform.translation = translation
        helicopterEntity?.helicopter?.transform.rotation = rotation
    }
    
    // MARK: - Animation Synchronization
    
    /// Switch between idle and moving animations (simplified)
    func updateMovementState(isMoving: Bool) {
        guard self.isMoving != isMoving else { return }
        
        self.isMoving = isMoving
        targetRotorSpeed = isMoving ? 1.0 : 0.3
        
        if abs(targetRotorSpeed - rotorSpeed) > 0.05 {
            startAnimationTimer()
        }
    }
    
    /// Update rotor animation (simplified)
    private func updateRotorAnimation() {
        rotorSpeed = rotorSpeed + (targetRotorSpeed - rotorSpeed) * 0.15
        
        if rotorSpeed > 0.1 && !rotorsActive {
            startRotors()
        } else if rotorSpeed < 0.1 && rotorsActive {
            stopRotors()
        }
        
        if abs(targetRotorSpeed - rotorSpeed) < 0.01 {
            stopAnimationTimer()
        }
    }
    
    /// Start rotor animations
    private func startRotors() {
        guard let helicopter = helicopterEntity else { return }
        rotorsActive = true
        helicopter.startRotorRotation()
    }
    
    /// Stop rotor animations
    private func stopRotors() {
        guard let helicopter = helicopterEntity else { return }
        rotorsActive = false
        helicopter.stopRotorRotation()
        stopAnimationTimer()
    }
    
    /// Start animation timer for smooth rotor speed transitions
    private func startAnimationTimer() {
        guard animationTimer == nil else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRotorAnimation()
            }
        }
    }
    
    /// Stop animation timer
    private func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - Network Synchronization
    
    /// Get current world transform (simplified)
    func getWorldTransform() -> simd_float4x4? {
        guard let anchor = anchorEntity, let helicopter = helicopterEntity?.helicopter else { return nil }
        return anchor.transform.matrix * simd_float4x4(helicopter.transform.rotation)
    }
    
    /// Update from received network data (for remote players)
    func updateFromNetwork(transform: simd_float4x4, isMoving: Bool) {
        guard !isLocalPlayer else { return }
        setWorldTransform(transform)
        updateMovementState(isMoving: isMoving)
    }
    
    // MARK: - Weapon Systems
    
    /// Toggle missile armed state
    func toggleMissileArmed() {
        helicopterEntity?.toggleArmMissile()
    }
    
    /// Check if missiles are armed
    func missilesArmed() -> Bool {
        return helicopterEntity?.missilesArmed ?? false
    }
    
    /// Fire missile (if armed)
    func fireMissile() -> Bool {
        guard missilesArmed() else { return false }
        
        os_log(.info, "Helicopter %d fired missile", index)
        
        // Create missile firing notification
        NotificationCenter.default.post(
            name: NSNotification.Name("HelicopterFiredMissile"),
            object: nil,
            userInfo: ["helicopterObject": self]
        )
        
        return true
    }
    
    // MARK: - Scene Management
    
    /// Add helicopter to AR scene
    func addToScene(_ scene: RealityKit.Scene) {
        guard let anchor = anchorEntity else { return }
        scene.addAnchor(anchor)
        
        os_log(.info, "Added helicopter %d to scene", index)
    }
    
    /// Remove helicopter from AR scene
    func removeFromScene() {
        anchorEntity?.removeFromParent()
        helicopterEntity?.stopRotorRotation()
        _cachedAnchorEntity = nil
        
        os_log(.info, "Removed helicopter %d from scene", index)
    }
    
    // MARK: - Health Management
    
    /// Make the helicopter take damage
    func takeDamage(_ damage: Float, from source: String = "enemy") {
        print("🚁 HelicopterObject takeDamage called: \(damage) from \(source)")
        print("🏥 Health system exists: \(healthSystem != nil)")
        if let health = healthSystem?.currentHealth {
            print("🩺 Current health before damage: \(health)")
        }
        healthSystem?.takeDamage(damage, from: source)
        if let health = healthSystem?.currentHealth {
            print("🩺 Current health after damage: \(health)")
        }
    }
    
    /// Heal the helicopter
    func heal(_ amount: Float) {
        healthSystem?.heal(amount)
    }
    
    /// Check if helicopter is alive
    func isAlive() -> Bool {
        return healthSystem?.isAlive ?? true
    }
    
    /// Get current health percentage
    func getHealthPercentage() -> Float {
        return healthSystem?.getHealthPercentage() ?? 100.0
    }
    
    /// Check if helicopter can take damage (not in immunity period)
    func canTakeDamage() -> Bool {
        return healthSystem?.canTakeDamage() ?? true
    }
    
    // MARK: - Cleanup
    
    @MainActor
    // MARK: - GameEntity Protocol Implementation
    
    func update(deltaTime: TimeInterval) {
        // Update helicopter animations and systems
        if !isDestroyed {
            updateRotorAnimation()
            // Health system is event-driven, no periodic updates needed
        }
    }
    
    @MainActor
    func cleanup() async {
        // Enhanced cleanup for GameEntity protocol
        isDestroyed = true
        _cachedAnchorEntity = nil
        
        animationTimer?.invalidate()
        anchorEntity?.removeFromParent()
        helicopterEntity?.stopRotorRotation()
        healthSystem?.cleanup()
        healthSystem = nil
    }
    
    @MainActor
    func onDestroy() {
        // Called when helicopter is destroyed (e.g., health reaches zero)
        Task { @MainActor in
            os_log(.info, "Helicopter %d destroyed", index)
        }
        cleanup()
    }
}
//    deinit {
//        // Cleanup on main actor without accessing actor-isolated state in deinit
//        Task { @MainActor [anchorEntity, helicopterEntity, animationTimer] in
//            animationTimer?.invalidate()
//            anchorEntity?.removeFromParent()
//            helicopterEntity?.stopRotorRotation()
//        }
//    }
//}

// MARK: - Extensions

extension HelicopterObject: Hashable {
    nonisolated static func == (lhs: HelicopterObject, rhs: HelicopterObject) -> Bool {
        return lhs.index == rhs.index
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(index)
    }
}

extension HelicopterObject: Identifiable {
    // Note: GameEntity.id is a String, Identifiable.id should also be String for consistency
}
