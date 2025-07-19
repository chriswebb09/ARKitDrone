//
//  FocusCircle.swift
//  ARKitDrone
//
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import Foundation
import UIKit

/**
 A RealityKit `Entity` that displays a focus circle with animated segments.
 */
class FocusCircle: Entity, HasModel {
    
    // MARK: - Types
    
    enum Quadrant {
        case topLeft, topRight, bottomLeft, bottomRight
        
        var angle: Float {
            switch self {
            case .topLeft: return Float.pi * 1.25
            case .topRight: return Float.pi * 1.75
            case .bottomRight: return Float.pi * 0.25
            case .bottomLeft: return Float.pi * 0.75
            }
        }
    }
    
    class Segment: Entity, HasModel {
        let quadrant: Quadrant
        
        init(name: String, quadrant: Quadrant) {
            self.quadrant = quadrant
            super.init()
            self.name = name
            setupSegment()
        }
        
        required init() {
            self.quadrant = .topLeft
            super.init()
            setupSegment()
        }
        
        private func setupSegment() {
            // Create arc segment geometry
            let radius: Float = 0.1
            let thickness: Float = 0.005
//            let arcLength: Float = Float.pi * 0.4 // 72 degrees
            
            // Create a simple box as segment (could be enhanced to actual arc)
            let segmentSize = SIMD3<Float>(radius * 0.3, thickness, thickness)
            let mesh = MeshResource.generateBox(size: segmentSize)
            
            // Create material
            var material = UnlitMaterial()
            material.color = .init(tint: FocusCircle.primaryColor)
            
            // Set up the model component
            self.components.set(ModelComponent(mesh: mesh, materials: [material]))
            
            // Position the segment based on quadrant
            positionSegment(radius: radius)
        }
        
        private func positionSegment(radius: Float) {
            let angle = quadrant.angle
            let x = cos(angle) * radius
            let z = sin(angle) * radius
            
            self.transform.translation = SIMD3<Float>(x, 0, z)
            self.transform.rotation = simd_quatf(angle: angle, axis: SIMD3<Float>(0, 1, 0))
        }
    }
    
    // MARK: - Configuration Properties
    
    static let primaryColor = UIColor(red: 1, green: 0.8, blue: 0, alpha: 1)
    static let animationDuration: Float = 1.0
    
    // MARK: - Properties
    
    private var segments: [Segment] = []
    private let positioningNode = Entity()
    private var isAnimating = false
    
    // MARK: - Initialization
    
    required init() {
        super.init()
        setupFocusCircle()
    }
    
    // MARK: - Setup
    
    private func setupFocusCircle() {
        // Create segments
        let s1 = Segment(name: "s1", quadrant: .topLeft)
        let s2 = Segment(name: "s2", quadrant: .topRight)
        let s3 = Segment(name: "s3", quadrant: .bottomRight)
        let s4 = Segment(name: "s4", quadrant: .bottomLeft)
        
        segments = [s1, s2, s3, s4]
        
        // Add segments to positioning node
        for segment in segments {
            positioningNode.addChild(segment)
        }
        
        // Add positioning node to self
        self.addChild(positioningNode)
        
        // Initially hide
        self.isEnabled = false
    }
    
    // MARK: - Public Interface
    
    /// Show the focus circle with animation
    func show() {
        self.isEnabled = true
        performPulseAnimation()
    }
    
    /// Hide the focus circle
    func hide() {
        self.isEnabled = false
    }
    
    /// Update position of the focus circle
    func updatePosition(_ position: SIMD3<Float>) {
        self.transform.translation = position
    }
    
    // MARK: - Animations
    
    private func performPulseAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        // Create pulsing scale animation
        let duration = TimeInterval(Self.animationDuration)
        
        // Create a simple pulsing animation
        let scaleUp = FromToByAnimation<Transform>(
            name: "pulseUp",
            from: Transform(scale: SIMD3<Float>(repeating: 1.0)),
            to: Transform(scale: SIMD3<Float>(repeating: 1.2)),
            duration: duration * 0.5,
            timing: .easeInOut,
            bindTarget: .transform
        )
        
        if let animationResource = try? AnimationResource.generate(with: scaleUp) {
            self.playAnimation(animationResource, transitionDuration: 0, startsPaused: false)
            
            // Schedule the reverse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.5) {
                self.performPulseDownAnimation()
            }
        }
        
        // Rotate segments continuously
        performSegmentRotation()
    }
    
    private func performPulseDownAnimation() {
        guard isAnimating else { return }
        
        let duration = TimeInterval(Self.animationDuration)
        
        let scaleDown = FromToByAnimation<Transform>(
            name: "pulseDown",
            from: Transform(scale: SIMD3<Float>(repeating: 1.2)),
            to: Transform(scale: SIMD3<Float>(repeating: 1.0)),
            duration: duration * 0.5,
            timing: .easeInOut,
            bindTarget: .transform
        )
        
        if let animationResource = try? AnimationResource.generate(with: scaleDown) {
            self.playAnimation(animationResource, transitionDuration: 0, startsPaused: false)
            
            // Repeat the cycle
            DispatchQueue.main.asyncAfter(deadline: .now() + duration * 0.5) {
                if self.isAnimating {
                    self.performPulseAnimation()
                }
            }
        }
    }
    
    private func performSegmentRotation() {
        for (index, segment) in segments.enumerated() {
            let delay = Float(index) * 0.1
            let duration = TimeInterval(Self.animationDuration * 2)
            
            // Create rotation animation
            let rotation = FromToByAnimation<Transform>(
                name: "segmentRotation_\(index)",
                from: Transform(rotation: segment.transform.rotation),
                to: Transform(rotation: segment.transform.rotation * simd_quatf(angle: Float.pi * 2, axis: SIMD3<Float>(0, 1, 0))),
                duration: duration,
                timing: .linear,
                bindTarget: .transform
            )
            
            if let animationResource = try? AnimationResource.generate(with: rotation) {
                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(delay)) {
                    segment.playAnimation(animationResource, transitionDuration: 0, startsPaused: false)
                }
            }
        }
    }
    
    /// Stop all animations
    func stopAnimations() {
        isAnimating = false
        self.stopAllAnimations()
        for segment in segments {
            segment.stopAllAnimations()
        }
    }
}
