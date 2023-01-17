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
    
    var stickNum: Int = 0
    var velocity: Float = 0
    var point = CGPoint(x: 0, y: 0)
    
    private lazy var joystick: Joystick = {
        var joystick = Joystick()
        joystick.position = CGPointMake(90, 85)
        return joystick
    }()
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        backgroundColor = .clear
        setupJoystick()
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        super.update(currentTime)
        if joystick.velocity.x != 0 || joystick.velocity.y != 0 {
            if abs(joystick.velocity.x) < abs(joystick.velocity.y) {
                joystickDelegate?.update(yValue: Float(joystick.velocity.y), stickNum: stickNum)
            } else {
                joystickDelegate?.update(xValue: Float(joystick.velocity.x), stickNum: stickNum)
            }
        }
    }
    
    private func setupNodes() {
        anchorPoint = point
    }
    
    private func setupJoystick() {
        addChild(joystick)
        joystick.delegate = self
    }
}

extension JoystickScene: JoystickDelegate {
    
    func tapped() {
        joystickDelegate?.tapped()
    }
}

