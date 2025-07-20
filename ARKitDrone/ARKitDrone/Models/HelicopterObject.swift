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

/// Multiplayer helicopter object similar to Tom & Jerry GameObject pattern
/// Each helicopter belongs to a specific player and syncs across all clients
@MainActor
class HelicopterObject: ObservableObject {
    
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
    
    // MARK: - Animation Properties
    
    /// Current rotor speed (0.0 = stopped, 1.0 = max speed)
    var rotorSpeed: Float = 0.0
    
    /// Whether rotors are currently spinning
    var rotorsActive: Bool = false
    
    /// Target rotor speed for smooth transitions
    private var targetRotorSpeed: Float = 0.0
    
    /// Timer for smooth rotor speed interpolation
    private var animationTimer: Timer?
    
    // MARK: - Movement Properties (matching Tom & Jerry smoothing)
    
    /// Target position for smooth movement interpolation
    private var targetTranslation = SIMD3<Float>(0, 0, 0)
    
    /// Target rotation for smooth rotation interpolation
    private var targetRotation = simd_quatf()
    
    /// How fast to interpolate towards target (matching ApacheHelicopter)
    private var smoothingFactor: Float = 0.15
    
    // MARK: - Network Sync Properties
    
    /// Whether this helicopter is owned by the local player
    var isLocalPlayer: Bool {
        guard let owner = owner else { return false }
        return owner == UserDefaults.standard.myself
    }
    
    /// Last known network position for dead reckoning
    private var lastNetworkTransform: simd_float4x4?
    
    /// Timestamp of last network update
    private var lastNetworkUpdate: TimeInterval = 0
    
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
        
        // Create helicopter instance
        helicopterEntity = await ApacheHelicopter()
        
        // Add helicopter to anchor
        if let helicopter = helicopterEntity?.helicopter,
           let anchor = anchorEntity {
            anchor.addChild(helicopter)
            
            // Initialize target transforms
            targetTranslation = translation
            targetRotation = helicopter.transform.rotation
            
            os_log(.info, "Helicopter setup complete for player %s", owner?.username ?? "unknown")
        }
    }
    
    // MARK: - Movement Methods (matching Tom & Jerry pattern)
    
    /// Update helicopter position from network or local input
    func updateMovement(moveData: MoveData) {
        guard let helicopter = helicopterEntity else { return }
        
        switch moveData.direction {
        case .forward:
            helicopter.moveForward(value: moveData.velocity.vector.y * 0.02)
        case .side:
            helicopter.moveSides(value: moveData.velocity.vector.x * 0.02)
        case .altitude:
            helicopter.changeAltitude(value: moveData.velocity.vector.y * 0.02)
        case .rotation:
            helicopter.rotate(yaw: moveData.velocity.vector.x * 0.02)
        case .none:
            // No specific direction, apply general movement
            helicopter.moveForward(value: moveData.velocity.vector.y * 0.02)
        @unknown default:
            os_log(.error, "Unknown movement direction in HelicopterObject.updateMovement")
        }
        
        // Update movement state for animation sync
        let hasMovement = simd_length(moveData.velocity.vector) > 0.001
        updateMovementState(isMoving: hasMovement)
    }
    
    /// Set position directly (for network synchronization)
    func setWorldTransform(_ transform: simd_float4x4) {
        guard let anchor = anchorEntity else { return }
        
        let translation = SIMD3<Float>(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        
        // Extract rotation from transform matrix
        let rotationMatrix = simd_float3x3(
            transform.columns.0.xyz,
            transform.columns.1.xyz,
            transform.columns.2.xyz
        )
        let rotation = simd_quatf(rotationMatrix)
        
        // Update anchor position
        anchor.transform.translation = translation
        
        // Update helicopter rotation if it exists
        if let helicopter = helicopterEntity?.helicopter {
            helicopter.transform.rotation = rotation
        }
        
        // Update targets for smooth interpolation
        targetTranslation = translation
        targetRotation = rotation
        
        lastNetworkTransform = transform
        lastNetworkUpdate = CACurrentMediaTime()
    }
    
    // MARK: - Animation Synchronization (matching Tom & Jerry pattern)
    
    /// Switch between idle and moving animations (like Tom & Jerry switchBetweenIdleAndRunning)
    func updateMovementState(isMoving: Bool) {
        guard self.isMoving != isMoving else { return }
        
        self.isMoving = isMoving
        
        // Update rotor speed based on movement
        targetRotorSpeed = isMoving ? 1.0 : 0.3
        
        // Start animation timer for smooth transitions
        if abs(targetRotorSpeed - rotorSpeed) > 0.05 {
            startAnimationTimer()
        }
        
        os_log(.info, "Helicopter %d movement state changed to: %@", 
               index, isMoving ? "moving" : "idle")
    }
    
    /// Update rotor animation based on movement state
    private func updateRotorAnimation() {
        // Smoothly interpolate rotor speed
        let previousSpeed = rotorSpeed
        rotorSpeed = rotorSpeed + (targetRotorSpeed - rotorSpeed) * 0.15
        
        // Enable/disable rotors based on speed
        if rotorSpeed > 0.1 && !rotorsActive {
            startRotors()
        } else if rotorSpeed < 0.1 && rotorsActive {
            stopRotors()
        }
        
        // Stop animation timer when transition is complete
        if abs(targetRotorSpeed - rotorSpeed) < 0.01 {
            stopAnimationTimer()
            os_log(.debug, "Helicopter %d rotor speed transition complete: %.2f", index, rotorSpeed)
        }
    }
    
    /// Start rotor animations
    private func startRotors() {
        guard let helicopter = helicopterEntity else { return }
        
        rotorsActive = true
        helicopter.startRotorRotation()
        
        os_log(.info, "Started rotors for helicopter %d", index)
    }
    
    /// Stop rotor animations
    private func stopRotors() {
        guard let helicopter = helicopterEntity else { return }
        
        rotorsActive = false
        helicopter.stopRotorRotation()
        stopAnimationTimer()
        
        os_log(.info, "Stopped rotors for helicopter %d", index)
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
    
    /// Get current world transform for network transmission
    func getWorldTransform() -> simd_float4x4? {
        guard let anchor = anchorEntity,
              let helicopter = helicopterEntity?.helicopter else { return nil }
        
        var transform = anchor.transform.matrix
        
        // Apply helicopter's local rotation
        let helicopterRotation = simd_float4x4(helicopter.transform.rotation)
        transform = transform * helicopterRotation
        
        return transform
    }
    
    /// Update from received network data (for remote players)
    func updateFromNetwork(transform: simd_float4x4, isMoving: Bool) {
        guard !isLocalPlayer else { return }
        
        setWorldTransform(transform)
        updateMovementState(isMoving: isMoving)
        
        os_log(.info, "Updated helicopter %d from network data", index)
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
        
        // TODO: Implement missile firing logic
        os_log(.info, "Helicopter %d fired missile", index)
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
        
        os_log(.info, "Removed helicopter %d from scene", index)
    }
    
    // MARK: - Cleanup
    
    @MainActor
    func cleanup() {
        animationTimer?.invalidate()
        anchorEntity?.removeFromParent()
        helicopterEntity?.stopRotorRotation()
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
    nonisolated var id: Int { return index }
}
