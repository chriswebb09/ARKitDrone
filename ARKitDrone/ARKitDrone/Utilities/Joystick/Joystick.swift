//
//  Joystick.swift
//  Swift-SpriteKit-Joystick
//
//  Created by Derrick Liu on 12/14/14.
//  Copyright (c) 2014 TheSneakyNarwhal. All rights reserved.
//

import Foundation
import SpriteKit

class Joystick: SKNode {
    
    private struct LocalConstants {
        static let kThumbSpringBack: Double =  0.04
        static let imageJoystickName: String = "joystick.png"
        static let imageDpadName: String = "dpad.png"
    }
    
    private let backdropNode, thumbNode: SKSpriteNode
    
    private var isTracking: Bool = false
    
    var angularVelocity: CGFloat = 0.0
    
    var velocity: CGPoint = .zero
    
    weak var delegate: JoystickDelegate?
    
    init(thumbNode: SKSpriteNode = SKSpriteNode(imageNamed: LocalConstants.imageJoystickName),
         backdropNode: SKSpriteNode = SKSpriteNode(imageNamed: LocalConstants.imageDpadName)) {
        
        self.thumbNode = thumbNode
        thumbNode.size = CGSize(width:  thumbNode.size.width  + 10, height: thumbNode.size.height  + 10)
        self.backdropNode = backdropNode
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
           self.thumbNode.frame.contains(touchPoint) {
            self.isTracking = true
        }
    }
    
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
        self.isTracking = false
        self.velocity = .zero
        let easeOut = SKAction.move(to: .zero, duration: LocalConstants.kThumbSpringBack)
        easeOut.timingMode = .easeOut
        thumbNode.removeAllActions()
        self.thumbNode.run(easeOut)
        
    }
    
    private func updateJoystick(touchPoint: CGPoint) {
        let thumbWidth = thumbNode.size.width
        let anchor = CGPoint.zero
        let dx = touchPoint.x
        let dy = touchPoint.y
        let distance = hypot(dx, dy)

        if isTracking && distance < thumbWidth {
            thumbNode.position = touchPoint
        } else {
            let angle = atan2(dy, dx)
            thumbNode.position = CGPoint(
                x: cos(angle) * thumbWidth,
                y: sin(angle) * thumbWidth
            )
        }

        let velocityX = thumbNode.position.x
        let velocityY = thumbNode.position.y

        velocity = CGPoint(x: velocityX, y: velocityY)
        angularVelocity = atan2(velocityY, velocityX)
    }
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
