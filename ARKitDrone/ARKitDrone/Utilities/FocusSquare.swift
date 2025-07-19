//
// FocusSquare.swift
// ARKitDrone
//
// Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

// Lightweight wrapper to avoid retaining full ARRaycastResult
struct LightweightRaycastResult {
    let worldTransform: simd_float4x4
    let anchor: ARAnchor?
}

class FocusSquare: Entity {
    enum State: Equatable {
        case initializing
        case detecting(raycastResult: ARRaycastResult, camera: ARCamera?)
    }
    
    static let size: Float = 0.5
    static let thickness: Float = 0.02
    static let scaleForClosedSquare: Float = 0.97
    static let sideLengthForOpenSegments: Float = 0.2
    
    static let primaryColor = UIColor(
        red: 1,
        green: 0.8,
        blue: 0,
        alpha: 1
    )
    
    static let fillColor = UIColor(
        red: 1,
        green: 0.9254901961,
        blue: 0.4117647059,
        alpha: 1
    )
    
    private var segmentPairs: [Entity] = []
    
    // MARK: - Throttling properties (disabled for max responsiveness)
    private var lastUpdateTime: TimeInterval = 0
    private let updateInterval: TimeInterval = 0.0 // No throttling - max responsiveness
    
    // MARK: - Animation state flags
    private var isAnimating = false
    private var isChangingAlignment = false
    
    var lastPosition: SIMD3<Float>? {
        switch state {
        case .initializing: return nil
        case .detecting(let raycastResult, _):
            return raycastResult.worldTransform.worldTranslation
        }
    }
    
    var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }
            DispatchQueue.main.async {
                self.updateAppearance()
            }
        }
    }
    
    required init() {
        super.init()
        setupFocusSquare()
    }
    
    private func setupFocusSquare() {
        createSimpleSquareOutline()
        self.isEnabled = true
        for segment in segmentPairs {
            segment.isEnabled = true
        }
    }
    
    private func createSimpleSquareOutline() {
        let halfSize = Self.size * 0.5
        let thickness = Self.thickness
        let segments = [
            (SIMD3<Float>(0, 0, -halfSize), SIMD3<Float>(Self.size, thickness, thickness)),
            (SIMD3<Float>(0, 0, halfSize), SIMD3<Float>(Self.size, thickness, thickness)),
            (SIMD3<Float>(-halfSize, 0, 0), SIMD3<Float>(thickness, thickness, Self.size)),
            (SIMD3<Float>(halfSize, 0, 0), SIMD3<Float>(thickness, thickness, Self.size))
        ]
        for (position, size) in segments {
            let segmentEntity = Entity()
            segmentEntity.transform.translation = position
            let mesh = MeshResource.generateBox(size: size)
            var material = UnlitMaterial()
            material.color = .init(tint: .yellow)
            segmentEntity.components.set(
                ModelComponent(
                    mesh: mesh,
                    materials: [material]
                )
            )
            segmentEntity.isEnabled = true
            self.addChild(segmentEntity)
            segmentPairs.append(segmentEntity)
        }
    }
    
    private func updateAppearance() {
        switch state {
        case .initializing:
            self.isEnabled = false
            stopFocusSquareAnimations()
        case .detecting(let raycastResult, let camera):
            self.isEnabled = true
            updatePositionSmoothly(
                for: raycastResult,
                camera: camera
            )
            updateFocusSquareAlignment(for: raycastResult)
            performOpenAnimation()
        }
    }
    
    private func stopFocusSquareAnimations() {
        self.stopAllAnimations(recursive: false)
        for segment in segmentPairs {
            segment.stopAllAnimations(recursive: false)
        }
        isAnimating = false
    }
    
    /// Smoothly updates position using lerp, throttled to updateInterval
    private func updatePositionSmoothly(for raycastResult: ARRaycastResult, camera: ARCamera?) {
        let now = CACurrentMediaTime()
        guard now - lastUpdateTime > updateInterval else { return }
        lastUpdateTime = now
        let position = raycastResult.worldTransform.worldTranslation
        // Move the parent anchor to the raycast position so focus square sits exactly on the detected plane
        if let parentAnchor = self.parent as? AnchorEntity {
            let transform = Transform(
                matrix: raycastResult.worldTransform
            )
            parentAnchor.reanchor(
                .world(
                    transform: transform.matrix
                )
            )
        } else {
            // Smoothly interpolate position to avoid snapping
            let currentPosition = self.transform.translation
            let lerpFactor: Float = 0.3
            let newPosition = simd_mix(
                currentPosition,
                position,
                SIMD3<Float>(repeating: lerpFactor)
            )
            self.transform.translation = newPosition
        }
        self.isEnabled = true
    }
    
    private func updateFocusSquareAlignment(for raycastResult: ARRaycastResult) {
        guard let anchor = raycastResult.anchor as? ARPlaneAnchor else { return }
        let planeNormal = SIMD3<Float>(anchor.transform.columns.1.x,
                                       anchor.transform.columns.1.y,
                                       anchor.transform.columns.1.z)
        let up = SIMD3<Float>(0, 1, 0)
        let normal = simd_normalize(planeNormal)
        if simd_length(simd_cross(up, normal)) > 0.001 {
            let rotationAxis = simd_normalize(simd_cross(up, normal))
            let angle = acos(simd_clamp(simd_dot(up, normal), -1.0, 1.0))
            let rotation = simd_quatf(
                angle: angle,
                axis: rotationAxis
            )
            if !isChangingAlignment {
                isChangingAlignment = true
                let currentRotation = self.transform.rotation
                let rotationAnimation = FromToByAnimation<Transform>(
                    name: "focusSquareAlign",
                    from: Transform(rotation: currentRotation),
                    to: Transform(rotation: rotation),
                    duration: 0.6, // slower smoother rotation
                    timing: .easeOut,
                    bindTarget: .transform
                )
                if let animationResource = try? AnimationResource.generate(with: rotationAnimation) {
                    self.playAnimation(animationResource)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.isChangingAlignment = false
                }
            }
        }
    }
    
    private func performOpenAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        for segment in segmentPairs {
            segment.isEnabled = true
            segment.transform.scale = SIMD3<Float>(repeating: 1.0)
        }
        self.isEnabled = true
        self.transform.scale = SIMD3<Float>(repeating: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {  // shorter delay, just enough for effect
            self.isAnimating = false
        }
    }
    
    func update(with raycastResult: ARRaycastResult?, camera: ARCamera?) {
        if let result = raycastResult {
            state = .detecting(
                raycastResult: result,
                camera: camera
            )
        } else {
            state = .initializing
        }
    }
    
    func updateWithLightweight(result lightweightResult: LightweightRaycastResult?, camera: ARCamera?) {
        if let result = lightweightResult {
            updatePositionDirectly(
                worldTransform: result.worldTransform,
                anchor: result.anchor,
                camera: camera
            )
            self.isEnabled = true
        } else {
            state = .initializing
        }
    }
    
    private func updatePositionDirectly(worldTransform: simd_float4x4, anchor: ARAnchor?, camera: ARCamera?) {
        let position = worldTransform.worldTranslation
        if let parentAnchor = self.parent as? AnchorEntity {
            let transform = Transform(matrix: worldTransform)
            parentAnchor.reanchor(.world(transform: transform.matrix))
        } else {
            // Directly set position here, or optionally smooth it
            self.transform.translation = position
        }
        
        self.isEnabled = true
    }
    
    func hide() {
        state = .initializing
        stopFocusSquareAnimations()
    }
    
    func unhide() {
        isEnabled = true
    }
    
    func updateFocusSquare(for arView: ARView, camera: ARCamera?) {
        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let results = arView.raycast(
            from: center,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        if let result = results.first {
            update(with: result, camera: camera)
        } else {
            update(with: nil, camera: camera)
        }
    }
}

extension simd_float4x4 {
    var worldTranslation: SIMD3<Float> {
        return SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
    
    var worldOrientation: simd_quatf {
        return simd_quaternion(self)
    }
}
