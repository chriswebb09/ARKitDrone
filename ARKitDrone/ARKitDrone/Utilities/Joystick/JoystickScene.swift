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
    var point = CGPoint.zero
    
    private lazy var joystick: Joystick = {
        let joystick = Joystick()
        joystick.position = CGPoint(x: 90, y: 80)
        joystick.delegate = self
        return joystick
    }()
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        self.backgroundColor = .clear
        self.setupJoystick()
    }
    
    override func update(_ currentTime: CFTimeInterval) {
        super.update(currentTime)
       
        let joystickVelocity = self.joystick.velocity
        
        if joystickVelocity != .zero {
            let isVertical = abs(joystickVelocity.y) > abs(joystickVelocity.x)
            if isVertical {
                let test = SIMD3<Float>(x: 0, y: Float(joystickVelocity.y), z: Float(joystickVelocity.y))
                self.joystickDelegate?.update(yValue: Float(joystickVelocity.y), velocity: test, angular:Float(self.joystick.angularVelocity), stickNum: self.stickNum)
            } else {
                let test = SIMD3<Float>(x: Float(joystickVelocity.x), y: 0, z: 0)
                self.joystickDelegate?.update(xValue: Float(joystickVelocity.x), velocity:test, angular: Float(self.joystick.angularVelocity), stickNum: self.stickNum)
            }
        }
    }
    
    private func setupJoystick() {
        addChild(joystick)
        anchorPoint = point  // Using the point property here
    }
}

extension JoystickScene: JoystickDelegate {
    
    func tapped() {
        joystickDelegate?.tapped()
    }
}
