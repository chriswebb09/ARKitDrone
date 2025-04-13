//
//  TargetNode.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/18/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

class TargetNode: SCNNode {
    
    let positioningNode = SCNNode()
    
    var segments: [FocusSquare.Segment] = []
    
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
    lazy var fillPlane: SCNNode = {
        let correctionFactor = FocusSquare.thickness / 2 // correction to align lines perfectly
        let length = CGFloat(1.0 - FocusSquare.thickness * 2 + correctionFactor)
        let plane = SCNPlane(width: length, height: length)
        let node = SCNNode(geometry: plane)
        node.name = "fillPlane"
        node.opacity = 0
        let material = plane.firstMaterial!
        material.diffuse.contents = TargetNode.fillColor
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = TargetNode.fillColor
        return node
    }()
    
    override init() {
        super.init()
        let s1 = FocusSquare.Segment(name: "s1", corner: .topLeft, alignment: .horizontal, color: TargetNode.fillColor, thickness: 0.04)
        let s2 = FocusSquare.Segment(name: "s2", corner: .topRight, alignment: .horizontal, color: TargetNode.fillColor, thickness: 0.04)
        let s3 = FocusSquare.Segment(name: "s3", corner: .topLeft, alignment: .vertical, color: TargetNode.fillColor, thickness: 0.04)
        let s4 = FocusSquare.Segment(name: "s4", corner: .topRight, alignment: .vertical, color: TargetNode.fillColor, thickness: 0.04)
        let s5 = FocusSquare.Segment(name: "s5", corner: .bottomLeft, alignment: .vertical, color: TargetNode.fillColor, thickness: 0.04)
        let s6 = FocusSquare.Segment(name: "s6", corner: .bottomRight, alignment: .vertical, color: TargetNode.fillColor, thickness: 0.04)
        let s7 = FocusSquare.Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal, color: TargetNode.fillColor, thickness: 0.04)
        let s8 = FocusSquare.Segment(name: "s8", corner: .bottomRight, alignment: .horizontal, color: TargetNode.fillColor, thickness: 0.04)
        segments = [s1, s2, s3, s4, s5, s6, s7, s8]
        
        let sl: Float = 0.5  // segment length
        let c: Float = FocusSquare.thickness / 2 // correction to align lines perfectly
        s1.simdPosition += [-(sl / 2 - c), -(sl - c), 0]
        s2.simdPosition += [sl / 2 - c, -(sl - c), 0]
        s3.simdPosition += [-sl, -sl / 2, 0]
        s4.simdPosition += [sl, -sl / 2, 0]
        s5.simdPosition += [-sl, sl / 2, 0]
        s6.simdPosition += [sl, sl / 2, 0]
        s7.simdPosition += [-(sl / 2 - c), sl - c, 0]
        s8.simdPosition += [sl / 2 - c, sl - c, 0]
        positioningNode.eulerAngles.x = .pi / 2 // Horizontal
        positioningNode.simdScale = [1.0, 1.0, 1.0] * (FocusSquare.size * FocusSquare.scaleForClosedSquare)
        for segment in segments {
            positioningNode.addChildNode(segment)
        }
        positioningNode.addChildNode(fillPlane)
        // Always render focus square on top of other content.
        displayNodeHierarchyOnTop(true)
        addChildNode(positioningNode)
        // Start the focus square as a billboard.
        displayAsBillboard()
        positioningNode.opacity = 1.0
        isOpen = true
        isPointingDownwards = true
    }
    
    private func displayAsBillboard() {
        simdTransform = matrix_identity_float4x4
        eulerAngles.x = .pi / 2
        simdPosition = [0, 0, -0.8]
        unhide()
        performOpenAnimation()
    }
    
    func unhide() {
        guard action(forKey: "unhide") == nil else { return }
        displayNodeHierarchyOnTop(true)
        runAction(.fadeIn(duration: 0.5), forKey: "unhide")
    }
    
    func performOpenAnimation() {
        guard !isOpen, !isAnimating else { return }
        isOpen = true
        isAnimating = true
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
        positioningNode.opacity = 1.0
        for segment in segments {
            segment.open()
        }
        SCNTransaction.completionBlock = {
            //            self.positioningNode.runAction(pulseAction(), forKey: "pulse")
            // This is a safe operation because `SCNTransaction`'s completion block is called back on the main thread.
            self.isAnimating = false
        }
        SCNTransaction.commit()
        // Add a scale/bounce animation.
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
        positioningNode.simdScale = [1.0, 1.0, 1.0] * FocusSquare.size
        SCNTransaction.commit()
    }
    
    func performCloseAnimation(flash: Bool = false) {
        guard isOpen, !isAnimating else { return }
        isOpen = false
        isAnimating = true
        positioningNode.removeAction(forKey: "pulse")
        positioningNode.opacity = 1.0
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 2
        positioningNode.opacity = 0.99
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
            for segment in self.segments {
                segment.close()
            }
            SCNTransaction.completionBlock = { self.isAnimating = false }
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
        positioningNode.opacity = 1
        // Scale/bounce animation
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transform.scale.x")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transform.scale.y")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transform.scale.z")
        
        if flash {
            let waitAction = SCNAction.wait(duration: FocusSquare.animationDuration * 0.75)
            let fadeInAction = SCNAction.fadeOpacity(to: 0.25, duration: FocusSquare.animationDuration * 0.125)
            let fadeOutAction = SCNAction.fadeOpacity(to: 0.0, duration: FocusSquare.animationDuration * 0.125)
            fillPlane.runAction(SCNAction.sequence([waitAction, fadeInAction, fadeOutAction]))
            let flashSquareAction = flashAnimation(duration: FocusSquare.animationDuration * 0.25)
            for segment in segments {
                segment.runAction(.sequence([waitAction, flashSquareAction]))
            }
        }
    }
    
    func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
        let scaleAnimation = CAKeyframeAnimation(keyPath: keyPath)
        let easeOut = CAMediaTimingFunction(name: .easeOut)
        let easeInOut = CAMediaTimingFunction(name: .easeInEaseOut)
        let linear = CAMediaTimingFunction(name: .linear)
        let size = FocusSquare.size
        let ts = FocusSquare.size * FocusSquare.scaleForClosedSquare
        let values = [size, size * 1.15, size * 1.15, ts * 0.97, ts]
        let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
        let timingFunctions = [easeOut, linear, easeOut, easeInOut]
        scaleAnimation.values = values
        scaleAnimation.keyTimes = keyTimes
        scaleAnimation.timingFunctions = timingFunctions
        scaleAnimation.duration = FocusSquare.animationDuration
        return scaleAnimation
    }
    
    func displayNodeHierarchyOnTop(_ isOnTop: Bool) {
        // Recursivley traverses the node's children to update the rendering order depending on the `isOnTop` parameter.
        func updateRenderOrder(for node: SCNNode) {
            node.renderingOrder = isOnTop ? 2 : 0
            for material in node.geometry?.materials ?? [] {
                material.readsFromDepthBuffer = !isOnTop
            }
            for child in node.childNodes {
                updateRenderOrder(for: child)
            }
        }
        updateRenderOrder(for: positioningNode)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


private func flashAnimation(duration: TimeInterval) -> SCNAction {
    
    let action = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> Void in
//        let elapsedTimePercentage = elapsedTime / CGFloat(duration)
//        let saturation = 2.8 * (elapsedTimePercentage - 0.5) * (elapsedTimePercentage - 0.5) + 0.3
        if let material = node.geometry?.firstMaterial {
            material.diffuse.contents = TargetNode.fillColor.withAlphaComponent(1.0)
        }
    }
    return action
    
}

