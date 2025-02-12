//
//  MinimapScene.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 2/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SpriteKit

class MinimapScene: SKScene {
    private var minimap: SKShapeNode!
    private var playerDot: SKShapeNode!
    private var shipDots: [SKShapeNode] = []
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        // Create the minimap circle
        let minimapRadius: CGFloat = 60
        minimap = SKShapeNode(circleOfRadius: minimapRadius)
        minimap.position = CGPoint(x: size.width / 2, y: size.height / 2)
        minimap.strokeColor = .white
        minimap.fillColor = UIColor(white: 0.2, alpha: 0.7)
        minimap.lineWidth = 2
        addChild(minimap)
        
        // Create player icon in the center
        playerDot = SKShapeNode(circleOfRadius: 5)
        playerDot.fillColor = .blue
        playerDot.position = .zero
        minimap.addChild(playerDot)
    }
    
    func updateMinimap(playerPosition: simd_float4, ships: [simd_float4], cameraRotation: simd_float4x4) {
        // Remove previous ship dots
        shipDots.forEach { $0.removeFromParent() }
        shipDots.removeAll()
        
        let minimapRadius: CGFloat = 260
        let worldRange: Float = 200
        let scale = minimapRadius / CGFloat(worldRange)
        let playerX = CGFloat(playerPosition.x) * scale
        let playerZ = CGFloat(playerPosition.z) * scale
        playerDot.position = CGPoint(x: playerX, y: playerZ)
        
        // Add ship dots to the minimap
        for shipPosition in ships {
            let shipX = CGFloat(shipPosition.x) * scale
            let shipZ = CGFloat(shipPosition.z) * scale
            // Apply camera rotation to invert map based on camera's facing direction
            let transformedShipPosition = applyCameraRotation(position: simd_float4(shipPosition.x, 0, shipPosition.z, 1), cameraRotation: cameraRotation)
            let invertedYPosition = -CGFloat(transformedShipPosition.z)
            let shipDot = SKShapeNode(circleOfRadius: 4)
            shipDot.fillColor = .red
            shipDot.position = CGPoint(x: CGFloat(transformedShipPosition.x) * scale, y: invertedYPosition * scale)
            minimap.addChild(shipDot)
            shipDots.append(shipDot)
        }
    }
    
    private func applyCameraRotation(position: simd_float4, cameraRotation: simd_float4x4) -> simd_float4 {
        let rotatedPosition = cameraRotation * position
        return rotatedPosition
    }
}
