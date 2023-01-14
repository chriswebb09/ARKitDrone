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
    
    let kThumbSpringBack: Double =  0.3
    let backdropNode, thumbNode: SKSpriteNode
    var isTracking: Bool = false
    var velocity: CGPoint = CGPointMake(0, 0)
    var travelLimit: CGPoint = CGPointMake(0, 0)
    var angularVelocity: CGFloat = 0.0
    var size: Float = 0.0
    
    func anchorPoint() -> CGPoint {
        return CGPointMake(0, 0)
    }
    
    weak var delegate: JoystickDelegate?
    
    init(thumbNode: SKSpriteNode = SKSpriteNode(imageNamed: "joystick.png"), backdropNode: SKSpriteNode = SKSpriteNode(imageNamed: "dpad.png")) {
        self.thumbNode = thumbNode
        self.backdropNode = backdropNode
        super.init()
        self.addChild(self.backdropNode)
        self.addChild(self.thumbNode)
        self.isUserInteractionEnabled = true
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint: CGPoint = (touch as AnyObject).location(in: self)
            let containsPoint = CGRectContainsPoint(self.thumbNode.frame, touchPoint)
            if self.isTracking == false && containsPoint {
                self.isTracking = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchPoint: CGPoint = (touch as AnyObject).location(in: self)
            let thumbWidth = Float(thumbNode.size.width)
            let anchorPointsY = anchorPoint().y
            let anchorPointsX = anchorPoint().x
            let thumbTouchX = Float(touchPoint.x) - Float(thumbNode.position.x)
            let thumbTouchY = Float(touchPoint.y) - Float(thumbNode.position.y)
            if isTracking == true &&
                sqrtf(powf((thumbTouchX), 2) + powf((thumbTouchY), 2)) < thumbWidth {
                let factorA = powf((Float(touchPoint.x) - Float(anchorPointsX)), 2)
                let factorB = powf((Float(touchPoint.y) - Float(anchorPointsY)), 2)
                if sqrtf(factorA + factorB) <= thumbWidth {
                    let moveDifferenceX = touchPoint.x - anchorPointsX
                    let moveDifferenceY = touchPoint.y - anchorPointsY
                    let moveDifference: CGPoint = CGPointMake(moveDifferenceX, moveDifferenceY)
                    let updatedThumbPositionX = anchorPointsX + moveDifference.x
                    let updatedThumbPositionY = anchorPointsY + moveDifference.y
                    thumbNode.position = CGPointMake(updatedThumbPositionX, updatedThumbPositionY)
                } else {
                    let vX: Double = Double(touchPoint.x) - Double(anchorPointsX)
                    let vY: Double = Double(touchPoint.y) - Double(anchorPointsY)
                    let magV: Double = sqrt(vX*vX + vY*vY)
                    let aX: Double = Double(anchorPointsX) + vX / magV * Double(thumbWidth)
                    let aY: Double = Double(anchorPointsY) + vY / magV * Double(thumbWidth)
                    thumbNode.position = CGPointMake(CGFloat(aX), CGFloat(aY))
                }
            }
            let velocityX = thumbNode.position.x - anchorPointsX
            let velocityY = thumbNode.position.y - anchorPointsY
            velocity = CGPointMake(velocityX, velocityY)
            let angularVelocityX = thumbNode.position.x - anchorPointsX
            let angularVelocityY = thumbNode.position.y - anchorPointsY
            angularVelocity = -atan2(angularVelocityX, angularVelocityY)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if velocity.x == 0 && velocity.y == 0 {
            delegate?.tapped()
        }
        resetVelocity()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetVelocity()
    }
    
    func resetVelocity() {
        isTracking = false
        velocity = CGPointZero
        let easeOut: SKAction = SKAction.move(to: anchorPoint(), duration: kThumbSpringBack)
        easeOut.timingMode = SKActionTimingMode.easeOut
        thumbNode.run(easeOut)
    }
}
