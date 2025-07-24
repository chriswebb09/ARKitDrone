//
//  Weapons.swift
//  ARKitDrone
//
//  Simplified weapon system
//

import Foundation
import RealityKit
import simd
import UIKit

// MARK: - Weapon Types

enum WeaponType: String, CaseIterable {
    case missile = "Missile"
    case gun = "Machine Gun"
    
    var fireRate: TimeInterval {
        switch self {
        case .missile: return 1.0
        case .gun: return 0.1
        }
    }
    
    var damage: Int {
        switch self {
        case .missile: return 100
        case .gun: return 25
        }
    }
}

// MARK: - Simple Bullet

@MainActor
class Bullet: GameEntity {
    let id: String
    let entity: Entity
    var isDestroyed: Bool = false
    
    private let damage: Int = 25
    private let speed: Float = 25.0
    private let lifetime: TimeInterval = 2.0
    private var startTime: TimeInterval = 0
    private var direction: SIMD3<Float> = SIMD3<Float>(0, 0, 1)
    
    init() {
        self.id = UUID().uuidString
        self.startTime = CACurrentMediaTime()
        
        // Create bullet visual
        let mesh = MeshResource.generateSphere(radius: 0.02)
        var material = UnlitMaterial()
        material.color = .init(tint: .yellow)
        
        self.entity = ModelEntity(mesh: mesh, materials: [material])
        self.entity.name = "Bullet_\(id)"
        
        // Add physics
        self.entity.physicsBody = PhysicsBodyComponent(
            massProperties: .default,
            material: .default,
            mode: .kinematic
        )
    }
    
    func fire(from position: SIMD3<Float>, direction: SIMD3<Float>) {
        self.direction = simd_normalize(direction)
        self.startTime = CACurrentMediaTime()
        entity.transform.translation = position
        isDestroyed = false
    }
    
    func update(deltaTime: TimeInterval) {
        guard !isDestroyed else { return }
        
        // Check lifetime
        if CACurrentMediaTime() - startTime > lifetime {
            cleanup()
            return
        }
        
        // Move bullet
        let movement = direction * speed * Float(deltaTime)
        entity.transform.translation += movement
        
        // Simple bounds check
        let position = entity.transform.translation
        if abs(position.x) > 50 || abs(position.y) > 50 || abs(position.z) > 50 {
            cleanup()
        }
    }
    
    func cleanup() {
        isDestroyed = true
        entity.removeFromParent()
    }
    
    func onDestroy() {
        cleanup()
    }
    
    func getDamage() -> Int { return damage }
}

// MARK: - Simplified Weapons System

@MainActor
class Weapons {
    
    // Current weapon state
    private var currentWeapon: WeaponType = .gun
    private var ammo: [WeaponType: Int] = [.missile: 10, .gun: 300]
    private var lastFireTime: [WeaponType: TimeInterval] = [:]
    
    // Bullet management
    private var activeBullets: [String: Bullet] = [:]
    
    // Dependencies
    private weak var scene: RealityKit.Scene?
    private weak var gameManager: GameManager?
    private let localPlayer: Player
    
    init(scene: RealityKit.Scene, gameManager: GameManager?, localPlayer: Player) {
        self.scene = scene
        self.gameManager = gameManager
        self.localPlayer = localPlayer
    }
    
    // MARK: - Weapon Control
    
    func switchWeapon() {
        currentWeapon = currentWeapon == .missile ? .gun : .missile
    }
    
    func getCurrentWeapon() -> WeaponType {
        return currentWeapon
    }
    
    func canFire() -> Bool {
        guard let ammoCount = ammo[currentWeapon], ammoCount > 0 else { return false }
        
        let currentTime = CACurrentMediaTime()
        if let lastFire = lastFireTime[currentWeapon] {
            return currentTime - lastFire >= currentWeapon.fireRate
        }
        return true
    }
    
    func fire() -> Bool {
        guard canFire() else { return false }
        
        // Update ammo and fire time
        if let currentAmmo = ammo[currentWeapon], currentAmmo > 0 {
            ammo[currentWeapon] = currentAmmo - 1
        }
        lastFireTime[currentWeapon] = CACurrentMediaTime()
        
        switch currentWeapon {
        case .missile:
            return fireMissile()
        case .gun:
            return fireGun()
        }
    }
    
    private func fireMissile() -> Bool {
        // Missiles handled by MissileManager
        return true
    }
    
    private func fireGun() -> Bool {
        guard let helicopterPos = getHelicopterPosition(),
              let scene = scene,
              activeBullets.count < 10 else { return false }
        
        let bullet = Bullet()
        let firePosition = helicopterPos + SIMD3<Float>(0.0, -0.2, 0.5)
        let fireDirection = SIMD3<Float>(0, 0, 1) // Forward
        
        bullet.fire(from: firePosition, direction: fireDirection)
        
        // Add to scene
        let anchor = AnchorEntity(world: firePosition)
        anchor.addChild(bullet.entity)
        scene.addAnchor(anchor)
        
        // Track bullet
        activeBullets[bullet.id] = bullet
        
        return true
    }
    
    // MARK: - Collision Handling
    
    func handleCollision(_ event: CollisionEvents.Began) {
        let entityA = event.entityA
        let entityB = event.entityB
        
        // Check for bullet-ship collisions
        if entityA.name.contains("Bullet") {
            handleBulletCollision(bullet: entityA, target: entityB)
        } else if entityB.name.contains("Bullet") {
            handleBulletCollision(bullet: entityB, target: entityA)
        }
    }
    
    private func handleBulletCollision(bullet: Entity, target: Entity) {
        guard let bulletObj = getBullet(from: bullet),
              let ship = Ship.getShip(from: target) else { return }
        
        // Apply damage and remove bullet
        ship.takeDamage(bulletObj.getDamage())
        removeBullet(bulletObj)
    }
    
    private func removeBullet(_ bullet: Bullet) {
        activeBullets.removeValue(forKey: bullet.id)
        bullet.cleanup()
    }
    
    private func getBullet(from entity: Entity) -> Bullet? {
        return activeBullets.values.first { $0.entity == entity }
    }
    
    // MARK: - Update
    
    func update(deltaTime: TimeInterval) {
        // Update all bullets
        for bullet in activeBullets.values {
            bullet.update(deltaTime: deltaTime)
        }
        
        // Remove destroyed bullets
        let destroyedBullets = activeBullets.values.filter { $0.isDestroyed }
        for bullet in destroyedBullets {
            removeBullet(bullet)
        }
    }
    
    // MARK: - Helpers
    
    private func getHelicopterPosition() -> SIMD3<Float>? {
        guard let helicopter = gameManager?.getHelicopter(for: localPlayer) else { return nil }
        
        if let anchor = helicopter.anchorEntity {
            return anchor.transform.translation
        } else if let helicopterEntity = helicopter.helicopterEntity?.helicopter {
            return helicopterEntity.transform.translation
        }
        return nil
    }
    
    // MARK: - Public API
    
    func getAmmo(for weaponType: WeaponType) -> Int {
        return ammo[weaponType] ?? 0
    }
    
    func reload(_ weaponType: WeaponType, amount: Int) {
        let currentAmmo = ammo[weaponType] ?? 0
        ammo[weaponType] = currentAmmo + amount
    }
    
    func getActiveBulletCount() -> Int {
        return activeBullets.count
    }
    
    func cleanup() {
        for bullet in activeBullets.values {
            bullet.cleanup()
        }
        activeBullets.removeAll()
    }
}