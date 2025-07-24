//
//  HelicopterHealthSystem.swift
//  ARKitDrone
//
//  Simplified helicopter health management
//

import Foundation
import RealityKit
import UIKit

@MainActor
class HelicopterHealthSystem {
    
    // MARK: - Health Properties
    
    var currentHealth: Float = 100.0
    var maxHealth: Float = 100.0
    var isAlive: Bool = true
    
    // Simple damage immunity
    private var lastDamageTime: TimeInterval = 0
    private let damageImmunityDuration: TimeInterval = 1.0
    
    // MARK: - Callbacks
    
    var onHealthChanged: ((Float, Float) -> Void)?
    var onDamageTaken: ((Float) -> Void)?
    var onCriticalHealth: (() -> Void)?
    var onHelicopterDestroyed: (() -> Void)?
    
    // MARK: - Initialization
    
    init(maxHealth: Float = 100.0) {
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
        self.isAlive = true
    }
    
    // MARK: - Health Management
    
    func takeDamage(_ damage: Float, from source: String = "unknown") {
        guard isAlive else { return }
        
        // Check damage immunity (skip for test sources)
        let currentTime = CACurrentMediaTime()
        if source != "test" && currentTime - lastDamageTime < damageImmunityDuration {
            return
        }
        
        lastDamageTime = currentTime
        
        // Only apply positive damage values - ignore negative damage
        if damage > 0 {
            currentHealth = max(0, currentHealth - damage)
        }
        
        // Trigger callbacks
        onHealthChanged?(currentHealth, maxHealth)
        onDamageTaken?(damage)
        
        // Check for critical health (25% or below)
        if currentHealth <= maxHealth * 0.25 {
            onCriticalHealth?()
        }
        
        // Check for death
        if currentHealth <= 0 {
            handleDestroyed()
        }
    }
    
    func heal(_ amount: Float) {
        guard isAlive else { return }
        
        currentHealth = min(maxHealth, currentHealth + amount)
        onHealthChanged?(currentHealth, maxHealth)
    }
    
    func resetHealth() {
        currentHealth = maxHealth
        isAlive = true
        onHealthChanged?(currentHealth, maxHealth)
    }
    
    // MARK: - Private Methods
    
    private func handleDestroyed() {
        isAlive = false
        onHelicopterDestroyed?()
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .helicopterDestroyed,
            object: nil
        )
    }
    
    // MARK: - Utility Methods
    
    func getHealthPercentage() -> Float {
        return (currentHealth / maxHealth) * 100
    }
    
    func getHealthString() -> String {
        return "\(Int(currentHealth))/\(Int(maxHealth))"
    }
    
    func canTakeDamage() -> Bool {
        let currentTime = CACurrentMediaTime()
        return isAlive && (currentTime - lastDamageTime >= damageImmunityDuration)
    }
    
    func isLowHealth() -> Bool {
        return getHealthPercentage() < 30.0
    }
    
    func isCriticalHealth() -> Bool {
        return getHealthPercentage() < 25.0
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        onHealthChanged = nil
        onDamageTaken = nil
        onCriticalHealth = nil
        onHelicopterDestroyed = nil
    }
}
