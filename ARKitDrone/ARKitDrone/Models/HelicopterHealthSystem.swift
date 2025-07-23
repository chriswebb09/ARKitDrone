//
//  HelicopterHealthSystem.swift
//  ARKitDrone
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import simd
import UIKit

@MainActor
class HelicopterHealthSystem: ObservableObject {
    
    // MARK: - Health Properties
    
    @Published var currentHealth: Float = 100.0
    @Published var maxHealth: Float = 100.0
    @Published var isAlive: Bool = true
    @Published var isDamaged: Bool = false
    @Published var isCritical: Bool = false
    
    // Health thresholds
    private let criticalHealthThreshold: Float = 25.0
    private let damagedHealthThreshold: Float = 60.0
    
    // MARK: - Visual Effects
    
    private weak var helicopterEntity: Entity?
    private var smokeEffects: [Entity] = []
    private var sparkEffects: [Entity] = []
    private var damageTimer: Timer?
    
    // MARK: - Damage System
    
    private var lastDamageTime: TimeInterval = 0
    private let damageImmunityDuration: TimeInterval = 1.0 // 1 second immunity after taking damage
    
    // MARK: - Callbacks
    
    var onHealthChanged: ((Float, Float) -> Void)?
    var onDamageTaken: ((Float) -> Void)?
    var onCriticalHealth: (() -> Void)?
    var onHelicopterDestroyed: (() -> Void)?
    
    // MARK: - Initialization
    
    init(maxHealth: Float = 100.0, helicopterEntity: Entity? = nil) {
        self.maxHealth = maxHealth
        self.currentHealth = maxHealth
        self.helicopterEntity = helicopterEntity
        self.isAlive = true
        
        updateHealthStates()
    }
    
    // MARK: - Health Management
    
    func takeDamage(_ damage: Float, from source: String = "unknown") {
        guard isAlive else { return }
        
        // Check damage immunity
        let currentTime = CACurrentMediaTime()
        if currentTime - lastDamageTime < damageImmunityDuration {
            print("🛡️ Damage blocked - immunity active (remaining: \(damageImmunityDuration - (currentTime - lastDamageTime))s)")
            return
        }
        
        lastDamageTime = currentTime
        
        let previousHealth = currentHealth
        currentHealth = max(0, currentHealth - damage)
        
        print("💥 Helicopter took \(damage) damage from \(source) - Health: \(currentHealth)/\(maxHealth)")
        
        // Update states
        updateHealthStates()
        
        // Trigger callbacks
        onHealthChanged?(currentHealth, maxHealth)
        onDamageTaken?(damage)
        
        // Check for critical health
        if isCritical && !isDamaged {
            onCriticalHealth?()
        }
        
        // Check for death
        if currentHealth <= 0 {
            handleHelicopterDestroyed()
        } else {
            // Add visual damage effects
            addDamageEffects(damageAmount: damage)
        }
    }
    
    func heal(_ amount: Float) {
        guard isAlive else { return }
        
        let previousHealth = currentHealth
        currentHealth = min(maxHealth, currentHealth + amount)
        
        print("💚 Helicopter healed \(amount) points - Health: \(currentHealth)/\(maxHealth)")
        
        updateHealthStates()
        onHealthChanged?(currentHealth, maxHealth)
        
        // Remove some damage effects if healing significantly
        if currentHealth > previousHealth + 10 {
            removeSomeVisualEffects()
        }
    }
    
    func resetHealth() {
        currentHealth = maxHealth
        isAlive = true
        updateHealthStates()
        removeAllVisualEffects()
        onHealthChanged?(currentHealth, maxHealth)
        
        print("🔄 Helicopter health reset to full")
    }
    
    // MARK: - State Management
    
    private func updateHealthStates() {
        let healthPercentage = (currentHealth / maxHealth) * 100
        
        isDamaged = healthPercentage < damagedHealthThreshold
        isCritical = healthPercentage < criticalHealthThreshold
        
        print("🏥 Health state - Damaged: \(isDamaged), Critical: \(isCritical), Percentage: \(healthPercentage)%")
    }
    
    private func handleHelicopterDestroyed() {
        isAlive = false
        isDamaged = true
        isCritical = true
        
        print("💀 Helicopter destroyed!")
        
        // Add destruction effects
        addDestructionEffects()
        
        // Trigger game over callback
        onHelicopterDestroyed?()
    }
    
    // MARK: - Visual Effects
    
    private func addDamageEffects(damageAmount: Float) {
        guard let helicopter = helicopterEntity else { return }
        
        // Add smoke effects for significant damage
        if damageAmount > 15 || isCritical {
            addSmokeEffect(to: helicopter)
        }
        
        // Add spark effects for any damage
        if damageAmount > 5 {
            addSparkEffect(to: helicopter)
        }
        
        // Make helicopter flash red briefly
        flashDamageIndicator()
    }
    
    private func addSmokeEffect(to helicopter: Entity) {
        // Create a simple smoke effect using a dark sphere
        let smoke = ModelEntity(
            mesh: .generateSphere(radius: 0.3),
            materials: [UnlitMaterial(color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.6))]
        )
        
        // Position randomly around the helicopter
        let smokePosition = SIMD3<Float>(
            Float.random(in: -0.5...0.5),
            Float.random(in: 0.2...0.8),
            Float.random(in: -0.3...0.3)
        )
        smoke.transform.translation = smokePosition
        
        helicopter.addChild(smoke)
        smokeEffects.append(smoke)
        
        // Animate smoke rising
        Task {
            let riseAnimation = FromToByAnimation<Transform>(
                name: "smokeRise",
                from: Transform(translation: smokePosition),
                to: Transform(translation: smokePosition + SIMD3<Float>(0, 2, 0)),
                duration: 3.0,
                timing: .easeOut,
                bindTarget: .transform
            )
            
            if let animationResource = try? AnimationResource.generate(with: riseAnimation) {
                smoke.playAnimation(animationResource)
            }
            
            // Remove smoke after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                smoke.removeFromParent()
                if let index = self.smokeEffects.firstIndex(of: smoke) {
                    self.smokeEffects.remove(at: index)
                }
            }
        }
    }
    
    private func addSparkEffect(to helicopter: Entity) {
        // Create sparks using small bright spheres
        for _ in 0..<5 {
            let spark = ModelEntity(
                mesh: .generateSphere(radius: 0.05),
                materials: [UnlitMaterial(color: UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0))]
            )
            
            let sparkDirection = SIMD3<Float>(
                Float.random(in: -1...1),
                Float.random(in: -0.5...1),
                Float.random(in: -1...1)
            )
            let sparkDistance = Float.random(in: 0.5...1.5)
            
            spark.transform.translation = SIMD3<Float>(0, 0, 0)
            helicopter.addChild(spark)
            sparkEffects.append(spark)
            
            // Animate sparks flying outward
            Task {
                let sparkAnimation = FromToByAnimation<Transform>(
                    name: "sparkFly",
                    from: Transform(translation: SIMD3<Float>(0, 0, 0)),
                    to: Transform(translation: simd_normalize(sparkDirection) * sparkDistance),
                    duration: 0.5,
                    timing: .easeOut,
                    bindTarget: .transform
                )
                
                if let animationResource = try? AnimationResource.generate(with: sparkAnimation) {
                    spark.playAnimation(animationResource)
                }
                
                // Remove spark after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    spark.removeFromParent()
                    if let index = self.sparkEffects.firstIndex(of: spark) {
                        self.sparkEffects.remove(at: index)
                    }
                }
            }
        }
    }
    
    private func flashDamageIndicator() {
        // This would typically flash the screen red or make the helicopter flash
        // For now, we'll just log it - the GameViewController can handle visual feedback
        print("🔴 Damage flash indicator triggered")
    }
    
    private func addDestructionEffects() {
        guard let helicopter = helicopterEntity else { return }
        
        // Add large explosion-like smoke
        for _ in 0..<8 {
            addSmokeEffect(to: helicopter)
        }
        
        // Add many sparks
        for _ in 0..<3 {
            addSparkEffect(to: helicopter)
        }
        
        print("💥 Destruction effects added")
    }
    
    private func removeSomeVisualEffects() {
        // Remove half of the smoke effects when healing
        let smokesToRemove = smokeEffects.prefix(smokeEffects.count / 2)
        for smoke in smokesToRemove {
            smoke.removeFromParent()
        }
        smokeEffects.removeFirst(min(smokeEffects.count / 2, smokeEffects.count))
        
        print("✨ Some damage effects removed due to healing")
    }
    
    private func removeAllVisualEffects() {
        // Remove all smoke and spark effects
        for smoke in smokeEffects {
            smoke.removeFromParent()
        }
        for spark in sparkEffects {
            spark.removeFromParent()
        }
        
        smokeEffects.removeAll()
        sparkEffects.removeAll()
        
        damageTimer?.invalidate()
        damageTimer = nil
        
        print("🧹 All visual damage effects removed")
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
    
    // MARK: - Cleanup
    
    func cleanup() {
        removeAllVisualEffects()
        helicopterEntity = nil
        onHealthChanged = nil
        onDamageTaken = nil
        onCriticalHealth = nil
        onHelicopterDestroyed = nil
    }
}
