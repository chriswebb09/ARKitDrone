////
////  Helicopter.swift
////  ARKitDrone
////
////  Created by Christopher Webb on 1/14/23.
////  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
////
//

import RealityKit
import ARKit
import Combine

@MainActor
class ApacheHelicopter {
    static var speed: Float = 50 // Static speed property for missile tracking
    
    var helicopter: Entity?
    var rotor: Entity?
    var tailRotor: Entity?
    var missiles: [Missile] = []  // Changed to match SceneKit
    var missileEntities: [Entity] = []  // Keep reference to raw entities
    var hudEntity: Entity?
    
    // Additional helicopter components matching SceneKit version
    var wingL: Entity?
    var wingR: Entity?
    var bodyEntity: Entity?
    var frontIRSteering: Entity?
    var frontIR: Entity?
    var upperGun: Entity?
    var missilesArmed: Bool = false
    
    // Manual rotor rotation
    private var rotorAngle: Float = 0
    private var tailRotorAngle: Float = 0
    private var rotorTimer: Timer?
    private var updateCounter: Int = 0 // Debug counter - used in updateRotorRotation()
    
    private var cancellables = Set<AnyCancellable>()
    
    // Movement smoothing properties
    private var targetTranslation = SIMD3<Float>(0, 0, 0)
    private var targetRotation = simd_quatf()
    private var smoothingFactor: Float = 0.15 // How fast to interpolate towards target
    
    init() async {
        await loadHelicopterModel()
    }
    
    deinit {
        Task { @MainActor [weak self] in
            self?.stopRotorRotation()
        }
    }
    
    private func loadHelicopterModel() async {
        do {
            // Use AsyncModelLoader with async Entity(named:) for Reality files
            let entity = try await AsyncModelLoader.shared.loadRealityModel(named: "heli")
            let model = entity.findEntity(named: "Model")
            self.helicopter = model?.findEntity(named: "Apache")
            // Apply helicopter orientation correction
            let originalRotation = simd_quatf(real: 0.7071069, imag: SIMD3<Float>(-0.70710665, 0.0, 0.0))
            let faceUserRotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
            let levelNose = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            let correctionRotation = originalRotation * faceUserRotation * levelNose
            self.helicopter?.scale = SIMD3<Float>(repeating: 0.4)
            self.helicopter?.transform.rotation = correctionRotation
            await self.setupHelicopterComponents()
            self.setupMissiles()
            self.adjustRotorPositions()
            self.startRotorRotation()
            // Initialize target transform values
            if let helicopter = self.helicopter {
                self.targetTranslation = helicopter.transform.translation
                self.targetRotation = helicopter.transform.rotation
            }
        } catch {
            print("❌ Failed to load helicopter: \(error)")
        }
    }
    
    private func setupHelicopterComponents() async {
        guard let helicopter = helicopter else {
            return
        }
        // Find all helicopter components matching SceneKit version
        self.hudEntity = helicopter.findEntity(named: "hud")
        self.rotor = helicopter.findEntity(named: "FrontRotor")
        self.tailRotor = helicopter.findEntity(named: "TailRotor")
        self.wingL = helicopter.findEntity(named: "Wing_L")
        self.wingR = helicopter.findEntity(named: "Wing_R")
        self.bodyEntity = helicopter.findEntity(named: "Body")
        self.frontIRSteering = helicopter.findEntity(named: "FrontIRSteering")
        self.upperGun = helicopter.findEntity(named: "UpperGun")
        // Setup frontIR if frontIRSteering exists
        if let frontIRSteering = self.frontIRSteering {
            self.frontIR = frontIRSteering.findEntity(named: "FrontIR")
        }
    }
    
    private func debugPrintEntityHierarchy(_ entity: Entity, indent: Int) {
        let indentString = String(repeating: "  ", count: indent)
        print("\(indentString)- \(entity.name)")
        for child in entity.children {
            debugPrintEntityHierarchy(child, indent: indent + 1)
        }
    }
    
    private func adjustRotorPositions() {
        // The rotors are children of the Body entity in the hierarchy
        // We should keep them in their relative positions but just adjust scale
        // Since they're children of Body, they'll move with the helicopter automatically
        if let rotor = rotor {
            rotor.transform.scale = SIMD3<Float>(repeating: 0.8)
        }
        if let tailRotor = tailRotor {
            tailRotor.transform.scale = SIMD3<Float>(repeating: 0.6)
        }
        
    }
    
    private func setupMissiles() {
        for i in 1...8 {
            if let missileEntity = helicopter?.findEntity(named: "Missile\(i)") {
                missileEntity.components.set(PhysicsBodyComponent(
                    massProperties: .default,
                    material: .default,
                    mode: .kinematic
                ))
                missileEntities.append(missileEntity)
                // Create Missile wrapper like SceneKit
                let missile = Missile()
                missile.setupEntity(entity: missileEntity, number: i)
                missiles.append(missile)
            }
        }
    }
    
    func startRotorRotation() {
        guard rotor != nil, tailRotor != nil else {
            return
        }
        // Stop any existing timer
        rotorTimer?.invalidate()
        // Create a timer to manually rotate the rotors - ensure it runs on main thread
        DispatchQueue.main.async { [weak self] in
            self?.rotorTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                Task { @MainActor in
                    self.updateRotorRotation()
                }
            }
            // Add timer to current run loop to ensure it runs
            if let timer = self?.rotorTimer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
    }
    
    @MainActor
    private func updateRotorRotation() {
        updateCounter += 1
        guard let rotor = rotor, let tailRotor = tailRotor else {
            return
        }
        // Increment rotation angles
        rotorAngle += 0.3 // Main rotor speed
        tailRotorAngle += 0.5 // Tail rotor speed (faster)
        // Keep angles in reasonable range
        if rotorAngle > .pi * 2 { rotorAngle -= .pi * 2 }
        if tailRotorAngle > .pi * 2 { tailRotorAngle -= .pi * 2 }
        // Apply rotations
        rotor.transform.rotation = simd_quatf(angle: rotorAngle, axis: [0, 1, 0]) // Y-axis
        tailRotor.transform.rotation = simd_quatf(angle: tailRotorAngle, axis: [1, 0, 0]) // X-axis
    }
    
    func stopRotorRotation() {
        rotorTimer?.invalidate()
        rotorTimer = nil
    }
    
    static func createRotorAnimation(axis: SIMD3<Float>, duration: TimeInterval) -> AnimationResource? {
        let anim = FromToByAnimation<Transform>(
            name: "rotorSpin",
            from: Transform(
                rotation: simd_quatf(
                    angle: 0,
                    axis: axis
                )
            ),
            to: Transform(
                rotation: simd_quatf(
                    angle: .pi * 2, // Full rotation
                    axis: axis
                )
            ),
            duration: duration,
            timing: .linear,
            bindTarget: .transform
        )
        // Create repeating animation using correct RealityKit API
        let animationResource = try? AnimationResource.generate(with: anim)
        return animationResource
    }
    
    func moveForward(value: Float) {
        guard let helicopter = helicopter else { return }
        let forward = helicopter.transform.matrix.columns.2
        let movementVector = SIMD3<Float>(
            forward.x,
            forward.y,
            forward.z
        ) * value
        targetTranslation -= movementVector
        // Apply smooth interpolation
        let currentTranslation = helicopter.transform.translation
        let newTranslation = simd_mix(
            currentTranslation,
            targetTranslation,
            SIMD3<Float>(repeating: smoothingFactor)
        )
        var transform = helicopter.transform
        transform.translation = newTranslation
        helicopter.transform = transform
        // Update target to current position for next frame
        targetTranslation = newTranslation
    }
    
    func rotate(yaw: Float) {
        guard let helicopter = helicopter else { return }
        let rotationDelta = simd_quatf(
            angle: yaw,
            axis: [0, 1, 0]
        )
        targetRotation = targetRotation * rotationDelta
        // Apply smooth interpolation
        let currentRotation = helicopter.transform.rotation
        let newRotation = simd_slerp(
            currentRotation,
            targetRotation,
            smoothingFactor
        )
        var transform = helicopter.transform
        transform.rotation = newRotation
        helicopter.transform = transform
        // Update target to current rotation for next frame
        targetRotation = newRotation
    }
    
    func changeAltitude(value: Float) {
        guard let helicopter = helicopter else { return }
        targetTranslation.y += value
        // Apply smooth interpolation
        let currentTranslation = helicopter.transform.translation
        let newTranslation = simd_mix(
            currentTranslation,
            targetTranslation,
            SIMD3<Float>(repeating: smoothingFactor)
        )
        var transform = helicopter.transform
        transform.translation = newTranslation
        helicopter.transform = transform
        // Update target to current position for next frame
        targetTranslation = newTranslation
    }
    
    func moveSides(value: Float) {
        guard let helicopter = helicopter else { return }
        let right = helicopter.transform.matrix.columns.0
        let movementVector = SIMD3<Float>(
            right.x,
            right.y,
            right.z
        ) * value
        targetTranslation += movementVector
        // Apply smooth interpolation
        let currentTranslation = helicopter.transform.translation
        let newTranslation = simd_mix(
            currentTranslation,
            targetTranslation,
            SIMD3<Float>(repeating: smoothingFactor)
        )
        var transform = helicopter.transform
        transform.translation = newTranslation
        helicopter.transform = transform
        // Update target to current position for next frame
        targetTranslation = newTranslation
    }
    
    // MARK: - Setup Methods
    
    /// Call this when helicopter position is changed externally (e.g., when placed by tap)
    func resetTargetTransform() {
        guard let helicopter = helicopter else { return }
        targetTranslation = helicopter.transform.translation
        targetRotation = helicopter.transform.rotation
    }
    
    func setup() async {
        // Initialize helicopter if not already loaded
        if helicopter == nil {
            await loadHelicopterModel()
        }
    }
    
    func setupHUD() {
        guard let hud = hudEntity else {
            return
        }
        // Position and scale HUD
        if let helicopter = helicopter {
            hud.transform.translation = helicopter.transform.translation
            // Offset HUD slightly forward
            let forward = helicopter.transform.matrix.columns.2
            hud.transform.translation -= SIMD3<Float>(
                forward.x,
                forward.y,
                forward.z
            ) * 0.44
        }
    }
    
    func updateHUD() {
        guard let hud = hudEntity, let helicopter = helicopter else { return }
        // Update HUD position and orientation to match helicopter
        hud.transform.rotation = helicopter.transform.rotation
        hud.transform.translation = helicopter.transform.translation
        // Maintain forward offset
        let forward = helicopter.transform.matrix.columns.2
        hud.transform.translation -= SIMD3<Float>(
            forward.x,
            forward.y,
            forward.z
        ) * 0.44
    }
    
    // MARK: - Missile System
    
    func toggleArmMissile() {
        missilesArmed = !missilesArmed
    }
    
    func missilesAreArmed() -> Bool {
        return missilesArmed
    }
    
    func lockOn(target: Entity) {
        guard let helicopter = helicopter, let hud = hudEntity else { return }
        let targetPosition = target.transform.translation
        let helicopterPosition = helicopter.transform.translation
        // Point HUD at target
        hud.transform.translation = helicopterPosition
        hud.look(
            at: targetPosition,
            from: helicopterPosition,
            relativeTo: nil
        )
        // Calculate distance and adjust HUD position
        let distance = simd_distance(
            helicopterPosition,
            targetPosition
        ) - 4
        let forward = hud.transform.matrix.columns.2
        hud.transform.translation -= SIMD3<Float>(
            forward.x,
            forward.y,
            forward.z
        ) * distance
    }
    
    // MARK: - Weapon Systems
    
    func shootUpperGun() -> Entity? {
        guard let helicopter = helicopter else {
            return nil
        }
        // Create bullet entity
        let bullet = Entity()
        // Create sphere mesh for bullet
        let geometry = MeshResource.generateSphere(radius: 0.002)
        var material = UnlitMaterial()
        material.color = .init(tint: .yellow)
        bullet.components.set(
            ModelComponent(
                mesh: geometry,
                materials: [material]
            )
        )
        // Position bullet at helicopter's gun position
        let helicopterTransform = helicopter.transform
        // Use actual upperGun position if available, otherwise use default offset
        if let upperGun = upperGun {
            bullet.transform.translation = upperGun.transform.translation
            bullet.transform.rotation = upperGun.transform.rotation
        } else {
            // Fallback to hardcoded offset
            let gunOffset = SIMD3<Float>(
                0.009,
                0.07,
                0.3
            )
            bullet.transform.translation = helicopterTransform.translation + gunOffset
            bullet.transform.rotation = helicopterTransform.rotation
        }
        // Add physics for movement
        let physicsComponent = PhysicsBodyComponent(
            massProperties: PhysicsMassProperties(mass: 0.01),
            material: PhysicsMaterialResource.default,
            mode: .dynamic
        )
        bullet.components.set(physicsComponent)
        // Add collision detection
        let collisionComponent = CollisionComponent(
            shapes: [ShapeResource.generateSphere(radius: 0.002)]
        )
        bullet.components.set(collisionComponent)
        // Note: Bullet physics handled by dynamic body component
        // Auto-remove bullet after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            bullet.removeFromParent()
        }
        return bullet
    }
}

