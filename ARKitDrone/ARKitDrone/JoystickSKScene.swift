//
//  JoystickSKScene.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 12/17/22.
//  Copyright © 2022 Christopher Webb-Orenstein. All rights reserved.
//


import SpriteKit

protocol JoystickSKSceneDelegate: AnyObject {
    func update(velocity: Float)
    func update(altitude: Float)
    func update(sides: Float)
}

class JoystickSKScene: SKScene {
    
    weak var joystickDelegate: JoystickSKSceneDelegate?
    
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
            joystickDelegate?.update(velocity: Float(joystick.velocity.y))
            joystickDelegate?.update(sides: Float(joystick.velocity.x))
        }
        
        if joystick2.velocity.x != 0 || joystick2.velocity.y != 0 {
            joystickDelegate?.update(altitude: Float(joystick2.velocity.y))
        }
    }
    
}
