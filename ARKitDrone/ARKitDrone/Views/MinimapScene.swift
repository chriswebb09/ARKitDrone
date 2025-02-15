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
    
    func updateMinimap(playerPosition: simd_float4, helicopterPosition: simd_float4, ships: [simd_float4], cameraRotation: simd_float4x4, placed: Bool) {
        
        shipDots.forEach { $0.removeFromParent() }
        shipDots.removeAll()
        helicopterDot?.removeFromParent()
        helicopterDot = nil
        
        let minimapRadius: CGFloat = 160
        let worldRange: Float = 32
        let scale = minimapRadius / CGFloat(worldRange)
        let playerX = CGFloat(playerPosition.x) * scale
        let playerZ = CGFloat(playerPosition.z) * scale
        playerDot.position = CGPoint(x: playerX, y: playerZ)
        
        if placed {
            helicopterDot = SKShapeNode(circleOfRadius: 5)
            helicopterDot.fillColor = .purple
            let transformedHelicopterPosition = applyCameraRotation(position: simd_float4(helicopterPosition.x, 0, helicopterPosition.z, 1), cameraRotation: cameraRotation)
            let invertedHelicopterYPosition = -CGFloat(transformedHelicopterPosition.z * 5)
            helicopterDot.position = CGPoint(x: CGFloat(transformedHelicopterPosition.x) * scale, y: invertedHelicopterYPosition * scale)
            cropNode.addChild(helicopterDot)
        }
        
        for shipPosition in ships {
            let transformedShipPosition = applyCameraRotation(position: simd_float4(shipPosition.x, 0, shipPosition.z, 1), cameraRotation: cameraRotation)
            let invertedYPosition = -CGFloat(transformedShipPosition.z)
            let shipDot = SKShapeNode(circleOfRadius: 4)
            shipDot.fillColor = .red
            shipDot.position = CGPoint(x: CGFloat(transformedShipPosition.x) * scale, y: invertedYPosition * scale)
            cropNode.addChild(shipDot)
            shipDots.append(shipDot)
        }
    }
    
    private func applyCameraRotation(position: simd_float4, cameraRotation: simd_float4x4) -> simd_float4 {
        let rotatedPosition = cameraRotation * position
        return rotatedPosition
    }
}
