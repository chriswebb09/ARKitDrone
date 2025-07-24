//
//  Joystick.swift
//  Swift-SpriteKit-Joystick
//
//  Created by Derrick Liu on 12/14/14.
//  Copyright (c) 2014 TheSneakyNarwhal. All rights reserved.
//

import Foundation
import SpriteKit
import os.log

class Joystick: SKNode {
    
    private struct LocalConstants {
        static let kThumbSpringBack: Double =  0.2
        static let imageJoystickName: String = "joystick.png"
        static let imageDpadName: String = "dpad.png"
        static let velocityMultiplier: CGFloat = 8
    }
    
    private let backdropNode, thumbNode: SKSpriteNode
    private var isTracking: Bool = false
    
    var angularVelocity: CGFloat = 0.0
    var velocity: CGPoint = .zero
    
    weak var delegate: JoystickDelegate?
    
    // Tap detection properties
    private var touchStartTime: TimeInterval = 0
    private var touchStartLocation: CGPoint = .zero
    private var hasMovedSignificantly: Bool = false
    
    init(thumbNode: SKSpriteNode = SKSpriteNode(imageNamed: LocalConstants.imageJoystickName), backdropNode: SKSpriteNode = SKSpriteNode(imageNamed: LocalConstants.imageDpadName)) {
        self.thumbNode = thumbNode
        self.backdropNode = backdropNode
        super.init()
        addChild(self.backdropNode)
        addChild(self.thumbNode)
        isUserInteractionEnabled = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Touches Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        if !self.isTracking,
           self.backdropNode.frame.contains(touchPoint) {
            self.isTracking = true
            self.touchStartTime = touch.timestamp
            self.touchStartLocation = touchPoint
            self.hasMovedSignificantly = false
            self.velocity = .zero // Ensure velocity starts at zero
            // DON'T update joystick on initial touch - wait for movement
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        // Check if movement is significant enough to consider it movement vs tap
        let distanceFromStart = sqrt(pow(touchPoint.x - touchStartLocation.x, 2) + pow(touchPoint.y - touchStartLocation.y, 2))
        // Only update joystick position if movement is significant enough
        if distanceFromStart > 5 { // 5 points threshold - responsive but prevents accidental taps
            hasMovedSignificantly = true
            self.updateJoystick(touchPoint: touchPoint)
        }
        // If movement is too small, don't update joystick at all
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard let touch = touches.first else { return }
        let touchDuration = touch.timestamp - touchStartTime
        // If no significant movement was detected, it's a tap
        let wasTap = !hasMovedSignificantly && touchDuration < 0.6
        if wasTap {
            DispatchQueue.main.async {
                self.delegate?.tapped()
            }
        }
        DispatchQueue.main.async {
            self.resetVelocity()
        }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        print("🎮 Touch CANCELLED")
        // If touch was cancelled but no significant movement occurred, treat as tap
        if !hasMovedSignificantly {
            print("🎯 Treating as TAP!")
            DispatchQueue.main.async {
                self.delegate?.tapped()
            }
        } else {
            print("🎮 Had movement - not firing")
        }
        DispatchQueue.main.async {
            self.resetVelocity()
        }
    }
    
    // MARK: - Private
    
    private func resetVelocity() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.resetVelocity()
            }
            return
        }
        self.isTracking = false
        self.velocity = .zero
        let easeOut = SKAction.move(
            to: .zero,
            duration: LocalConstants.kThumbSpringBack
        )
        easeOut.timingMode = .easeOut
        thumbNode.removeAllActions()
        self.thumbNode.run(easeOut)
    }
    
    private func updateJoystick(touchPoint: CGPoint) {
        guard isTracking else { return }
        // Use actual thumb position for velocity calculations
        // This approach gives a more direct control feel
        //  let thumbWidth = thumbNode.size.width / 2
        let maxDistance = backdropNode.size.width / 2 - 10
        let dx = touchPoint.x
        let dy = touchPoint.y
        let distance = sqrt(dx * dx + dy * dy)
        let angle = atan2(dy, dx)
        // Position the thumb
        if distance < maxDistance {
            thumbNode.position = touchPoint
        } else {
            let newX = cos(angle) * maxDistance
            let newY = sin(angle) * maxDistance
            thumbNode.position = CGPoint(x: newX, y: newY)
        }
        // Set velocity directly based on thumb position
        // This preserves the original behavior while adding the multiplier
        let newVelocity = CGPoint(
            x: thumbNode.position.x * LocalConstants.velocityMultiplier,
            y: thumbNode.position.y * LocalConstants.velocityMultiplier
        )
        // Only update velocity if movement is significant enough to prevent tiny movements
        let velocityMagnitude = sqrt(newVelocity.x * newVelocity.x + newVelocity.y * newVelocity.y)
        if velocityMagnitude > 0.5 { // Minimum velocity threshold - low for responsiveness
            velocity = newVelocity
            angularVelocity = atan2(velocity.y, velocity.x)
        } else {
            velocity = .zero
            angularVelocity = 0
        }
    }
}

private extension CGPoint {
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
