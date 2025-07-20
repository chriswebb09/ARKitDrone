//
//  ReticleEntity.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/18/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import ARKit

class ReticleEntity: Entity {
    
    let positioningEntity = Entity()
    
    var segments: [FocusSquareSegment] = []
    
    var isOpen = false
    
    /// Indicates if the square is currently being animated for opening or closing.
    var isAnimating = false
    
    /// Indicates if the square is currently changing its orientation when the camera is pointing downwards.
    var isChangingOrientation = false
    
    /// Indicates if the camera is currently pointing towards the floor.
    var isPointingDownwards = true
    
    static let primaryColor = UIColor.green
    
    // Color of the focus square fill.
    static let fillColor = UIColor.green
    
    /// The focus square's most recent positions.
    var recentFocusSquarePositions: [SIMD3<Float>] = []
    
    private var fillPlane: Entity!
    
    required init() {
        super.init()
        // Create simple green corner brackets for targeting
        createCornerBrackets()
        addChild(positioningEntity)

        // Start the target as visible
        displayAsBillboard()
        isOpen = true
        isPointingDownwards = true
    }
    
    private func createCornerBrackets() {
        // Create 8 simple corner bracket entities
        let thickness: Float = 0.02
        let bracketLength: Float = 0.15
        let squareSize: Float = 0.6
        
        // Create material
        var material = UnlitMaterial()
        material.color = .init(tint: ReticleEntity.primaryColor)
        
        // Top-left corner (L-shape)
        let tlHoriz = Entity()
        tlHoriz.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(bracketLength, thickness, thickness)
                ),
                materials: [material]
            )
        )
        tlHoriz.transform.translation = SIMD3<Float>(-squareSize/2 + bracketLength/2, -squareSize/2, 0)
        
        let tlVert = Entity()
        tlVert.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(thickness, bracketLength, thickness)
                ),
                materials: [material]
            )
        )
        tlVert.transform.translation = SIMD3<Float>(-squareSize/2, -squareSize/2 + bracketLength/2, 0)
        
        // Top-right corner (L-shape)
        let trHoriz = Entity()
        trHoriz.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(bracketLength, thickness, thickness)
                ),
                materials: [material]
            )
        )
        trHoriz.transform.translation = SIMD3<Float>(squareSize/2 - bracketLength/2, -squareSize/2, 0)
        
        let trVert = Entity()
        trVert.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(thickness, bracketLength, thickness)
                ),
                materials: [material]
            )
        )
        trVert.transform.translation = SIMD3<Float>(squareSize/2, -squareSize/2 + bracketLength/2, 0)
        
        // Bottom-left corner (L-shape)
        let blHoriz = Entity()
        blHoriz.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(bracketLength, thickness, thickness)
                ),
                materials: [material]
            )
        )
        blHoriz.transform.translation = SIMD3<Float>(-squareSize/2 + bracketLength/2, squareSize/2, 0)
        
        let blVert = Entity()
        blVert.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(thickness, bracketLength, thickness)
                ),
                materials: [material]
            )
        )
        blVert.transform.translation = SIMD3<Float>(-squareSize/2, squareSize/2 - bracketLength/2, 0)
        
        // Bottom-right corner (L-shape)
        let brHoriz = Entity()
        brHoriz.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(bracketLength, thickness, thickness)
                ),
                materials: [material]
            )
        )
        brHoriz.transform.translation = SIMD3<Float>(squareSize/2 - bracketLength/2, squareSize/2, 0)
        
        let brVert = Entity()
        brVert.components.set(
            ModelComponent(
                mesh: MeshResource.generateBox(
                    size: SIMD3<Float>(
                        thickness,
                        bracketLength,
                        thickness
                    )
                ),
                materials: [material]
            )
        )
        brVert.transform.translation = SIMD3<Float>(squareSize/2, squareSize/2 - bracketLength/2, 0)
        
        // Add all brackets to positioning entity
        positioningEntity.addChild(tlHoriz)
        positioningEntity.addChild(tlVert)
        positioningEntity.addChild(trHoriz)
        positioningEntity.addChild(trVert)
        positioningEntity.addChild(blHoriz)
        positioningEntity.addChild(blVert)
        positioningEntity.addChild(brHoriz)
        positioningEntity.addChild(brVert)
        
        // Set basic transform - make it vertical (no rotation) with small base scale
        positioningEntity.transform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
        positioningEntity.transform.scale = SIMD3<Float>(repeating: 0.2)  // Small base scale
    }
    
    private func createFillPlane() {
        let correctionFactor: Float = 0.009 // thickness / 2 correction to align lines perfectly
        let length = 1.0 - 0.018 * 2 + correctionFactor
        
        let mesh = MeshResource.generatePlane(
            width: length,
            depth: length
        )
        fillPlane = Entity()
        fillPlane.name = "fillPlane"
        
        var material = UnlitMaterial()
        material.color = .init(tint: ReticleEntity.fillColor.withAlphaComponent(0.0))
        
        fillPlane.components.set(
            ModelComponent(
                mesh: mesh,
                materials: [material]
            )
        )
    }
    
    private func displayAsBillboard() {
        transform = Transform.identity
        transform.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])  // Keep vertical
        transform.translation = [0, 0, 0]  // Don't offset
        unhide()
        performOpenAnimation()
    }
    
    func unhide() {
        isEnabled = true
    }
    
    func performOpenAnimation() {
        guard !isOpen, !isAnimating else { return }
        isOpen = true
        isAnimating = true
        
        // Simple scale animation for green targeting brackets
        let scaleAnimation = FromToByAnimation<Transform>(
            name: "openScale",
            from: Transform(scale: SIMD3<Float>(repeating: 0.8)),
            to: Transform(scale: SIMD3<Float>(repeating: 1.0)),
            duration: 0.175,
            timing: .easeOut,
            bindTarget: .transform
        )
        
        if let animationResource = try? AnimationResource.generate(with: scaleAnimation) {
            positioningEntity.playAnimation(animationResource)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.175) {
                self.isAnimating = false
            }
        }
    }
    
    func performCloseAnimation(flash: Bool = false) {
        guard isOpen, !isAnimating else { return }
        isOpen = false
        isAnimating = true
        // Simple scale down animation for the green square
        let scaleAnimation = FromToByAnimation<Transform>(
            name: "closeScale",
            from: Transform(scale: SIMD3<Float>(repeating: 1.0)),
            to: Transform(scale: SIMD3<Float>(repeating: 0.5)),
            duration: 0.35,
            timing: .easeOut,
            bindTarget: .transform
        )
        
        if let animationResource = try? AnimationResource.generate(with: scaleAnimation) {
            positioningEntity.playAnimation(animationResource)
            if flash {
                performFlashEffect()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isAnimating = false
            }
        }
    }
    
    private func performFlashEffect() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.525) {
            if var model = self.fillPlane.components[ModelComponent.self] {
                var material = UnlitMaterial()
                material.color = .init(tint: ReticleEntity.fillColor.withAlphaComponent(0.25))
                model.materials = [material]
                self.fillPlane.components.set(model)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0875) {
                    var material = UnlitMaterial()
                    material.color = .init(tint: ReticleEntity.fillColor.withAlphaComponent(0.0))
                    model.materials = [material]
                    self.fillPlane.components.set(model)
                }
            }
        }
    }
}

// MARK: - FocusSquareSegment for RealityKit

class FocusSquareSegment: Entity {
    
    enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }
    
    enum Alignment {
        case horizontal
        case vertical
    }
    
    var corner: Corner
    var alignment: Alignment
    var isOpen = false
    
    init(name: String, corner: Corner, alignment: Alignment, color: UIColor, thickness: Float) {
        self.corner = corner
        self.alignment = alignment
        super.init()
        self.name = name
        // Create short corner bracket segments for proper focus square look
        let bracketLength: Float = 0.2  // Short segments for corner brackets
        let segmentSize = alignment == .horizontal ?
        SIMD3<Float>(bracketLength, thickness, thickness) :
        SIMD3<Float>(thickness, bracketLength, thickness)
        let mesh = MeshResource.generateBox(size: segmentSize)
        var material = UnlitMaterial()
        material.color = .init(tint: color)
        components.set(ModelComponent(mesh: mesh, materials: [material]))
    }
    
    required init() {
        self.corner = .topLeft
        self.alignment = .horizontal
        super.init()
    }
    
    func open() {
        isOpen = true
        // Segments start in open position
    }
    
    func close() {
        isOpen = false
        // Segments close animation
    }
}
