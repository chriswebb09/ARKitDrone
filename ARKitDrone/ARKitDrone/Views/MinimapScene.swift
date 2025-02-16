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
    private var missileDots: [SKShapeNode] = []
    private var helicopterDot: SKShapeNode!
    private var cropNode: SKCropNode!
    
    override func didMove(to view: SKView) {
        backgroundColor = .clear
        
        let minimapRadius: CGFloat = 60
        minimap = SKShapeNode(circleOfRadius: minimapRadius)
        minimap.position = CGPoint(x: size.width / 2, y: size.height / 2)
        minimap.strokeColor = .white
        minimap.fillColor = UIColor(white: 0.2, alpha: 0.7)
        minimap.lineWidth = 2
        addChild(minimap)
        
        cropNode = SKCropNode()
        cropNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        let mask = SKShapeNode(circleOfRadius: minimapRadius)
        mask.fillColor = .white
        mask.strokeColor = .clear
        cropNode.maskNode = mask
        addChild(cropNode)
        
        playerDot = SKShapeNode(circleOfRadius: 5)
        playerDot.fillColor = .blue
        playerDot.position = .zero
        cropNode.addChild(playerDot)
    }
    
    func updateMinimap(playerPosition: simd_float4, helicopterPosition: simd_float4, ships: [simd_float4], missiles: [simd_float4], cameraRotation: simd_float4x4, placed: Bool) {
        let minimapRadius: CGFloat = 180
        let worldRange: Float = 90
        let scale = minimapRadius / CGFloat(worldRange)
        
        // Update player position on the minimap
        let playerX = CGFloat(playerPosition.x) * scale
        let playerZ = CGFloat(playerPosition.z) * scale
        playerDot.position = CGPoint(x: playerX, y: playerZ)
        
        // Update helicopter position if placed
        if placed {
            if helicopterDot == nil {
                helicopterDot = SKShapeNode(circleOfRadius: 3)
                helicopterDot?.fillColor = .purple
                cropNode.addChild(helicopterDot!)
            }
            
            let transformedHelicopterPosition = applyCameraRotation(position: helicopterPosition, cameraRotation: cameraRotation)
            let invertedHelicopterYPosition = -CGFloat(transformedHelicopterPosition.z * 5)
            helicopterDot?.position = CGPoint(x: CGFloat(transformedHelicopterPosition.x) * scale, y: invertedHelicopterYPosition * scale)
        }
        
        // Update ship positions
        shipDots.forEach { $0.removeFromParent() }
        shipDots.removeAll()
        
        missileDots.forEach { $0.removeFromParent() }
        missileDots.removeAll()
        
        for shipPosition in ships {
            let transformedShipPosition = applyCameraRotation(position: shipPosition, cameraRotation: cameraRotation)
            let invertedYPosition = -CGFloat(transformedShipPosition.z * 0.45)
            let shipDot = SKShapeNode(circleOfRadius: 3)
            shipDot.fillColor = .red
            shipDot.position = CGPoint(x: CGFloat(transformedShipPosition.x) * scale, y: invertedYPosition * scale)
            cropNode.addChild(shipDot)
            shipDots.append(shipDot)
        }
        
        for missilePosition in missiles {
            let transformedMissilePosition = applyCameraRotation(position: missilePosition, cameraRotation: cameraRotation)
            let invertedYPosition = -CGFloat(transformedMissilePosition.z * 0.55)
            let missileDot = SKShapeNode(circleOfRadius: 1)
            missileDot.fillColor = .orange
            missileDot.position = CGPoint(x: CGFloat(transformedMissilePosition.x) * scale, y: invertedYPosition * scale)
            cropNode.addChild(missileDot)
            missileDots.append(missileDot)
        }
    }
    
    
    
    private func applyCameraRotation(position: simd_float4, cameraRotation: simd_float4x4) -> simd_float4 {
        let rotatedPosition = cameraRotation * position
        return rotatedPosition
    }
}
