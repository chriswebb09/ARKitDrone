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
        static let velocityMultiplier: CGFloat = 2
    }
    
    private let backdropNode, thumbNode: SKSpriteNode
    
    private var isTracking: Bool = false
    
    var angularVelocity: CGFloat = 0.0
    
    var velocity: CGPoint = .zero
    
    weak var delegate: JoystickDelegate?
    
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
        //        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        if !self.isTracking,
           self.backdropNode.frame.contains(touchPoint) {
            self.isTracking = true
            updateJoystick(touchPoint: touchPoint)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        self.updateJoystick(touchPoint: touchPoint)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        print("touches ended")
        DispatchQueue.main.async {
            self.delegate?.tapped()
            if self.velocity == .zero {
                
            }
            self.resetVelocity()
        }
//        self.resetVelocity()
        
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
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
        let easeOut = SKAction.move(to: .zero, duration: LocalConstants.kThumbSpringBack)
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
        velocity = CGPoint(
            x: thumbNode.position.x * LocalConstants.velocityMultiplier,
            y: thumbNode.position.y * LocalConstants.velocityMultiplier
        )
        angularVelocity = atan2(velocity.y, velocity.x)
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
