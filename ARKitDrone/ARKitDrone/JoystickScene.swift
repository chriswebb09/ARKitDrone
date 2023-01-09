//
//  JoystickSKScene.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 12/17/22.
//  Copyright © 2022 Christopher Webb-Orenstein. All rights reserved.
//


import SpriteKit

class JoystickScene: SKScene {
    
    weak var joystickDelegate: JoystickSceneDelegate?
    
    var velocity: Float = 0
    
    var point = CGPoint(x: 0, y: 0)
    
    lazy var joystick: Joystick = {
        var joystick = Joystick()
        joystick.position = CGPointMake(70, 250)
        return joystick
    }()
    
    lazy var joystick2: Joystick = {
        var joystick = Joystick()
        joystick.position = CGPointMake(400, 100)
        return joystick
    }()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        setupJoystick()
    }
    
    func setupNodes() {
        anchorPoint = point
    }
    
    func setupJoystick() {
        self.addChild(joystick)
        self.addChild(joystick2)
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        if joystick.velocity.x != 0 || joystick.velocity.y != 0 {
            if abs(joystick.velocity.x) < abs(joystick.velocity.y) {
                joystickDelegate?.update(velocity: Float(joystick.velocity.y))
            } else {
                joystickDelegate?.update(rotate: Float(joystick.velocity.x))
            }
        }
        
        if joystick2.velocity.x != 0 || joystick2.velocity.y != 0 {
            if abs(joystick2.velocity.x) < abs(joystick2.velocity.y) {
                joystickDelegate?.update(altitude: Float(joystick2.velocity.y))
            } else {
                joystickDelegate?.update(sides: Float(joystick2.velocity.x))
            }
        }
    }
}
