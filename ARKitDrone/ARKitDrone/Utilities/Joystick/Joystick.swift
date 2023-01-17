//
//  Joystick.swift
//  Swift-SpriteKit-Joystick
//
//  Created by Derrick Liu on 12/14/14.
//  Copyright (c) 2014 TheSneakyNarwhal. All rights reserved.
//

import Foundation
import SpriteKit

class Joystick : SKNode {
    
    private struct LocalConstants {
        static let kThumbSpringBack: Double =  0.3
    }

    private let backdropNode, thumbNode: SKSpriteNode
    private var isTracking: Bool = false
    private var angularVelocity: CGFloat = 0.0
    
    var velocity: CGPoint = CGPointMake(0, 0)
    
    weak var delegate: JoystickDelegate?
    
    init(thumbNode: SKSpriteNode = SKSpriteNode(imageNamed: "joystick.png"), backdropNode: SKSpriteNode = SKSpriteNode(imageNamed: "dpad.png")) {
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
        super.touchesBegan(touches, with: event)
        for touch in touches {
            let touchPoint: CGPoint = (touch as AnyObject).location(in: self)
            let containsPoint = CGRectContainsPoint(thumbNode.frame, touchPoint)
            if isTracking == false && containsPoint {
                isTracking = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            let touchPoint: CGPoint = (touch as AnyObject).location(in: self)
            updateJoystick(touchPoint: touchPoint)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        if velocity.x == 0 && velocity.y == 0 {
            delegate?.tapped()
        }
        resetVelocity()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        resetVelocity()
    }
    
    // MARK: - Private
    
    private func resetVelocity() {
        isTracking = false
        velocity = CGPointZero
        let easeOut: SKAction = SKAction.move(to: CGPoint(x: 0, y: 0), duration: LocalConstants.kThumbSpringBack)
        easeOut.timingMode = SKActionTimingMode.easeOut
        thumbNode.run(easeOut)
    }
    
    private func updateJoystick(touchPoint: CGPoint) {
        let thumbWidth = Float(thumbNode.size.width)
        let anchor = CGPoint(x: 0, y: 0)
        let anchorPointsY = anchor.y
        let anchorPointsX = anchor.x
        let thumbTouchX = Float(touchPoint.x) - Float(thumbNode.position.x)
        let thumbTouchY = Float(touchPoint.y) - Float(thumbNode.position.y)
        if isTracking == true &&
            sqrtf(powf((thumbTouchX), 2) + powf((thumbTouchY), 2)) < thumbWidth {
            let factorA = powf((Float(touchPoint.x) - Float(anchorPointsX)), 2)
            let factorB = powf((Float(touchPoint.y) - Float(anchorPointsY)), 2)
            if sqrtf(factorA + factorB) <= thumbWidth {
                let moveDifferenceX = touchPoint.x - anchorPointsX
                let moveDifferenceY = touchPoint.y - anchorPointsY
                let moveDifference: CGPoint = CGPoint(x: moveDifferenceX,y: moveDifferenceY)
                let updatedThumbPositionX = anchorPointsX + moveDifference.x
                let updatedThumbPositionY = anchorPointsY + moveDifference.y
                thumbNode.position = CGPoint(x: updatedThumbPositionX, y: updatedThumbPositionY)
            } else {
                let vX: Double = Double(touchPoint.x) - Double(anchorPointsX)
                let vY: Double = Double(touchPoint.y) - Double(anchorPointsY)
                let magV: Double = sqrt(vX*vX + vY*vY)
                let aX: Double = Double(anchorPointsX) + vX / magV * Double(thumbWidth)
                let aY: Double = Double(anchorPointsY) + vY / magV * Double(thumbWidth)
                thumbNode.position = CGPoint(x: CGFloat(aX), y: CGFloat(aY))
            }
        }
        let velocityX = thumbNode.position.x - anchorPointsX
        let velocityY = thumbNode.position.y - anchorPointsY
        velocity = CGPoint(x: velocityX, y: velocityY)
        let angularVelocityX = thumbNode.position.x - anchorPointsX
        let angularVelocityY = thumbNode.position.y - anchorPointsY
        angularVelocity = -atan2(angularVelocityX, angularVelocityY)
    }
}
