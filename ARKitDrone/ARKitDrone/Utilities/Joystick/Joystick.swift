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

    override init() {
        
        self.thumbNode =  SKSpriteNode(imageNamed: LocalConstants.imageJoystickName)
        thumbNode.size = CGSize(width:  thumbNode.size.width  + 10, height: thumbNode.size.height  + 10)
        self.backdropNode = SKSpriteNode(imageNamed: LocalConstants.imageDpadName)
        backdropNode.size = CGSize(width:  backdropNode.size.width  + 10, height: backdropNode.size.height  + 10)
        super.init()
        isUserInteractionEnabled = true
        addChild(self.backdropNode)
        addChild(self.thumbNode)
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Touches Lifecycle
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        if !self.isTracking,
           self.backdropNode.frame.contains(touchPoint) {
            self.isTracking = true
            updateJoystick(touchPoint: touchPoint)
        }
    }
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        super.touchesBegan(touches, with: event)
    //        guard let touch = touches.first else { return }
    //        let touchPoint = touch.location(in: self)
    //        if !self.isTracking,
    //           self.thumbNode.frame.contains(touchPoint) {
    //            self.isTracking = true
    //        }
    //    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        guard let touch = touches.first else { return }
        let touchPoint = touch.location(in: self)
        self.updateJoystick(touchPoint: touchPoint)
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if self.velocity == .zero {
            self.delegate?.tapped()
        }
        self.resetVelocity()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        self.resetVelocity()
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
           let maxDistance = backdropNode.size.width / 2
           
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
//    private func updateJoystick(touchPoint: CGPoint) {
//            guard isTracking else { return }
//            
//            // Calculate distance between touch point and center
//            let dx = touchPoint.x
//            let dy = touchPoint.y
//            let distance = sqrt(dx * dx + dy * dy)
//            
//            // Get the maximum radius the thumb can move (use the backdrop radius)
//            let maxDistance = backdropNode.size.width / 2
//            
//            if distance < maxDistance {
//                // If within bounds, move thumb directly to touch point
//                thumbNode.position = touchPoint
//            } else {
//                // If beyond bounds, clamp to the edge of the allowed circle
//                let angle = atan2(dy, dx)
//                let newX = cos(angle) * maxDistance
//                let newY = sin(angle) * maxDistance
//                thumbNode.position = CGPoint(x: newX, y: newY)
//            }
//            
//            // Calculate normalized velocity (0 to 1 in each direction)
//            let normalizedDistance = min(distance / maxDistance, 1.0)
//            let normalizedX = cos(atan2(dy, dx)) * normalizedDistance
//            let normalizedY = sin(atan2(dy, dx)) * normalizedDistance
//            
//            // Update velocity and angular velocity
//            velocity = CGPoint(x: normalizedX, y: normalizedY)
//            angularVelocity = atan2(velocity.y, velocity.x)
//        }
    
//    private func updateJoystick(touchPoint: CGPoint) {
//        let thumbWidth = thumbNode.size.width
//        let anchor = CGPoint.zero
//        let dx = touchPoint.x
//        let dy = touchPoint.y
//        let distance = hypot(dx, dy)
//        
//        if isTracking && distance < thumbWidth {
//            thumbNode.position = touchPoint
//        } else {
//            let angle = atan2(dy, dx)
//            thumbNode.position = CGPoint(
//                x: cos(angle) * thumbWidth,
//                y: sin(angle) * thumbWidth
//            )
//        }
//        
//        let velocityX = thumbNode.position.x
//        let velocityY = thumbNode.position.y
//        
//        velocity = CGPoint(x: velocityX, y: velocityY)
//        angularVelocity = atan2(velocityY, velocityX)
//    }
    //        let thumbWidth = thumbNode.size.width
    //        let anchor = CGPoint.zero
    //        let distance = touchPoint.distance(to: thumbNode.position)
    //        if isTracking, distance < thumbWidth {
    //            self.thumbNode.position = touchPoint
    //        } else {
    //            let angle = atan2(touchPoint.y - anchor.y, touchPoint.x - anchor.x)
    //            let clampedX = anchor.x + cos(angle) * thumbWidth
    //            let clampedY = anchor.y + sin(angle) * thumbWidth
    //            self.thumbNode.position = CGPoint(x: clampedX, y: clampedY)
    //        }
    //        self.velocity = self.thumbNode.position - anchor
    //        self.angularVelocity = atan2(self.velocity.y, self.velocity.x)
    //    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
}
