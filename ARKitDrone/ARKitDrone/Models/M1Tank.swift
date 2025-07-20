//
//  M1Tank.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/31/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import ARKit
import simd

// MARK: - M1 Abrams Tank
@MainActor
class M1AbramsTank {
    
    private struct LocalConstants {
        static let sceneName = "m1tankmodel"
        static let tank = "m1tank"
        static let turret = "turret"
        static let maingun = "gun"
        static let body = "body"
    }
    
    var tankRotateAngle: Double = 0.0
    private var tankEntity: Entity!
    private var tracksEntity: Entity?
    private var turretEntity: Entity?
    private var mainGunEntity: Entity?
    private var maxUp: Float = -0.133
    private var maxDown: Float = 0.133
    
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var firingRange: Float = 20.0
    var moveSpeed: Float = 0.5
    var forwardAngleThreshold: Float = 45.0
    var maxRotation: Float = 0
    
    func setup(with arView: ARView, transform: simd_float4x4) async {
        do {
            // Load tank model exactly like the original working code
            let entity = try await AsyncModelLoader.shared.loadModel(named: LocalConstants.sceneName)
            let tankRootEntity: Entity
            if let rootEntity = entity.findEntity(named: "root") {
                tankRootEntity = rootEntity
            } else {
                tankRootEntity = entity
            }
            tankRootEntity.name = "Tank"
            tankRootEntity.scale = SIMD3<Float>(repeating: 0.1)
            tankRootEntity.isEnabled = true
            tankRootEntity.transform.rotation = simd_quatf(
                angle: -Float.pi / 2,
                axis: SIMD3<Float>(1, 0, 0)
            )
            
            // Add physics to body entity if found (like original)
            if let bodyEntity = tankRootEntity.findEntity(named: "body") {
                let bounds = bodyEntity.visualBounds(relativeTo: nil).extents
                bodyEntity.components.set(CollisionComponent(shapes: [.generateBox(size: bounds)]))
                bodyEntity.components.set(PhysicsBodyComponent(massProperties: .default, material: .default, mode: .static))
            }
            
            // Wrap in ModelEntity if needed (like original)
            if let modelEntity = tankRootEntity as? ModelEntity {
                self.tankEntity = modelEntity
            } else {
                let wrapperEntity = ModelEntity()
                wrapperEntity.name = "TankWrapper"
                wrapperEntity.addChild(tankRootEntity)
                self.tankEntity = wrapperEntity
            }
            
            // Position tank using raycast result (like original)
            let tankPosition = SIMD3<Float>(
                transform.columns.3.x,
                transform.columns.3.y,
                transform.columns.3.z
            )
            let adjustedPosition = SIMD3<Float>(
                tankPosition.x,
                tankPosition.y + 0.05,
                tankPosition.z
            )
            
            // Create anchor for tank (like original)
            let tankAnchor = AnchorEntity(world: adjustedPosition)
            tankAnchor.addChild(tankEntity)
            arView.scene.addAnchor(tankAnchor)
            
        } catch {
            print("❌ Failed to load tank model: \(error)")
            return
        }
    }
    
}

// MARK: - Tank Operations

extension M1AbramsTank {
    
    func place(transform: simd_float4x4) {
        Task { @MainActor in
            tankEntity.transform.matrix = transform
        }
    }
    
    func rotate(angle: Float) {
        let rotationAnimation = FromToByAnimation<Transform>(
            name: "tankRotation",
            from: Transform(rotation: tankEntity.transform.rotation),
            to: Transform(
                rotation: tankEntity.transform.rotation * simd_quatf(
                    angle: angle * Float.pi,
                    axis: SIMD3<Float>(0, 0, 1)
                )
            ),
            duration: 0.25,
            timing: .easeOut,
            bindTarget: .transform
        )
        if let animationResource = try? AnimationResource.generate(with: rotationAnimation) {
            tankEntity.playAnimation(animationResource)
        }
    }
    
    func rotateTurret(rotation: Float) {
        guard let turretEntity = turretEntity else { return }
        let turretRotation = FromToByAnimation<Transform>(
            name: "turretRotation",
            from: Transform(
                rotation: turretEntity.transform.rotation
            ),
            to: Transform(
                rotation: turretEntity.transform.rotation * simd_quatf(
                    angle: rotation * Float.pi,
                    axis: SIMD3<Float>(0, 0, 1)
                )
            ),
            duration: 0.25,
            timing: .easeOut,
            bindTarget: .transform
        )
        if let animationResource = try? AnimationResource.generate(with: turretRotation) {
            turretEntity.playAnimation(animationResource)
        }
    }
    
    func moveTurretVertical(value: Float) {
        // Placeholder for vertical turret movement
        // Can be implemented with pitch rotation on the gun entity
    }
    
    func fire() async {
        guard let mainGunEntity = mainGunEntity else { return }
        let shell = await Shell.createShell()
        // Position shell at gun muzzle
        shell.entity.transform.translation = mainGunEntity.convert(
            position: SIMD3<Float>(1.0, 0, 0),
            to: tankEntity
        )
        // Add shell to parent
        if let parent = tankEntity.parent {
            parent.addChild(shell.entity)
        }
        // Calculate firing direction based on gun orientation
        let gunWorldTransform = mainGunEntity.convert(
            transform: Transform.identity,
            to: tankEntity
        )
        let firingDirection = normalize(
            gunWorldTransform.rotation.act(
                SIMD3<Float>(1, 0, 0)
            )
        )
        launchProjectile(entity: shell.entity, direction: firingDirection)
    }
    
    private func launchProjectile(entity: Entity, direction: SIMD3<Float>) {
        // Animate shell movement
        let targetPosition = entity.transform.translation + direction * 100
        let projectileAnimation = FromToByAnimation<Transform>(
            name: "shellFlight",
            from: Transform(
                translation: entity.transform.translation
            ),
            to: Transform(translation: targetPosition),
            duration: 3.0,
            timing: .linear,
            bindTarget: .transform
        )
        if let animationResource = try? AnimationResource.generate(with: projectileAnimation) {
            entity.playAnimation(animationResource)
            // Remove shell after flight
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                entity.removeFromParent()
            }
        }
    }
    
    func move(direction: Float) {
        let moveDistance = direction * 0.8
        let moveAnimation = FromToByAnimation<Transform>(
            name: "tankMovement",
            from: Transform(translation: tankEntity.transform.translation),
            to: Transform(
                translation: tankEntity.transform.translation + SIMD3<Float>(0, moveDistance, 0)
            ),
            duration: 0.25,
            timing: .easeOut,
            bindTarget: .transform
        )
        if let animationResource = try? AnimationResource.generate(with: moveAnimation) {
            tankEntity.playAnimation(animationResource)
        }
    }
    
    func distanceToTarget(_ target: M1AbramsTank) -> Float {
        let delta = target.tankEntity.transform.translation - self.tankEntity.transform.translation
        return length(SIMD2<Float>(delta.x, delta.z))
    }
    
    func angleToTarget(_ target: M1AbramsTank) -> Float {
        let delta = target.tankEntity.transform.translation - self.tankEntity.transform.translation
        return atan2(delta.z, delta.x) * 180 / .pi
    }
    
    func hasLineOfSight(to target: M1AbramsTank) -> Bool {
        return true
    }
    
    func decideToEngage(against opponent: M1AbramsTank) async {
        let distance = distanceToTarget(opponent)
        let angleToOpponent = angleToTarget(opponent)
        if abs(angleToOpponent) <= forwardAngleThreshold {
            print("M1 Abrams Tank: Opponent is in front.")
            if distance <= firingRange && hasLineOfSight(to: opponent) {
                print("M1 Abrams Tank: Engaging opponent. Target within range and clear line of sight.")
                await fire()
            } else {
                print("M1 Abrams Tank: Not in range. Moving toward opponent.")
                move(direction: 1.0)
            }
        } else {
            print("M1 Abrams Tank: Opponent is not in front, repositioning.")
            rotate(angle: angleToOpponent)
            move(direction: 1.0)
        }
    }
}
