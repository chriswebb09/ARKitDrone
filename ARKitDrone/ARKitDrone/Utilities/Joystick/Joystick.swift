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
        static let kThumbSpringBack: Double =  0.3
        static let imageJoystickName: String = "joystick.png"
        static let imageDpadName: String = "dpad.png"
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
        super.touchesBegan(touches, with: event)

        DispatchQueue.main.async {
            guard let touch = touches.first else { return }
            let touchPoint = touch.location(in: self)
            if !self.isTracking, self.thumbNode.frame.contains(touchPoint) {
                self.isTracking = true
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        DispatchQueue.main.async {
            guard let touch = touches.first else { return }
            let touchPoint = touch.location(in: self)
            self.updateJoystick(touchPoint: touchPoint)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        DispatchQueue.main.async {
            if self.velocity == .zero {
                self.delegate?.tapped()
            }
            self.resetVelocity()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        DispatchQueue.main.async {
            self.resetVelocity()
        }
    }
    
    // MARK: - Private
    
    private func resetVelocity() {
        isTracking = false
        velocity = .zero
        let easeOut = SKAction.move(to: .zero, duration: LocalConstants.kThumbSpringBack)
        easeOut.timingMode = .easeOut
        thumbNode.run(easeOut)
    }
    
    private func updateJoystick(touchPoint: CGPoint) {
        let thumbWidth = thumbNode.size.width
        let anchor = CGPoint.zero
        let distance = touchPoint.distance(to: thumbNode.position)
        if isTracking, distance < thumbWidth {
            thumbNode.position = touchPoint
        } else {
            let angle = atan2(touchPoint.y - anchor.y, touchPoint.x - anchor.x)
            let clampedX = anchor.x + cos(angle) * thumbWidth
            let clampedY = anchor.y + sin(angle) * thumbWidth
            thumbNode.position = CGPoint(x: clampedX, y: clampedY)
        }
        velocity = thumbNode.position - anchor
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


//
//  AnalogStick.swift
//  Joystick
//
//  Created by Dmitriy Mitrophanskiy on 28.09.14.
//
//
import SpriteKit


//
//  ARJoystickSKScene.swift
//  ARJoystick
//
//  Created by Alex Nagy on 27/07/2018.
//  Copyright © 2018 Alex Nagy. All rights reserved.
//

import SpriteKit

class ARJoystickSKScene: SKScene {
    
    enum NodesZPosition: CGFloat {
        case joystick
    }
    
    lazy var analogJoystick: AnalogJoystick = {
        let js = AnalogJoystick(diameter: 100, colors: nil, images: (substrate: UIImage(named: "jSubstrate"), stick: UIImage(named: "jStick")))
        js.position = CGPoint(x: js.radius + 40, y: js.radius + 40)
        js.zPosition = NodesZPosition.joystick.rawValue
        return js
    }()
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        setupNodes()
        setupJoystick()
    }
    
    func setupNodes() {
        anchorPoint = CGPoint(x: 0.0, y: 0.0)
    }
    
    func setupJoystick() {
        addChild(analogJoystick)
        
        analogJoystick.trackingHandler = { data in
            NotificationCenter.default.post(name: joystickNotificationName, object: nil, userInfo: ["data": data])
        }
        
    }
    
}




















//MARK: AnalogJoystickData
public struct AnalogJoystickData: CustomStringConvertible {
    var velocity = CGPoint.zero,
    angular = CGFloat(0)
    
    mutating func reset() {
        velocity = CGPoint.zero
        angular = 0
    }
    
    public var description: String {
        return "AnalogStickData(velocity: \(velocity), angular: \(angular))"
    }
}

//MARK: - AnalogJoystickComponent
open class AnalogJoystickComponent: SKSpriteNode {
    private var kvoContext = UInt8(1)
    var borderWidth = CGFloat(0) {
        didSet {
            redrawTexture()
        }
    }
    
    var borderColor = UIColor.black {
        didSet {
            redrawTexture()
        }
    }
    
    var image: UIImage? {
        didSet {
            redrawTexture()
        }
    }
    
    var diameter: CGFloat {
        get {
            return max(size.width, size.height)
        }
        
        set(newSize) {
            size = CGSize(width: newSize, height: newSize)
        }
    }
    
    var radius: CGFloat {
        get {
            return diameter * 0.5
        }
        
        set(newRadius) {
            diameter = newRadius * 2
        }
    }
    
    //MARK: - DESIGNATED
    init(diameter: CGFloat, color: UIColor? = nil, image: UIImage? = nil) {
        super.init(texture: nil, color: color ?? UIColor.black, size: CGSize(width: diameter, height: diameter))
        addObserver(self, forKeyPath: "color", options: NSKeyValueObservingOptions.old, context: &kvoContext)
        self.diameter = diameter
        self.image = image
        redrawTexture()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObserver(self, forKeyPath: "color")
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        redrawTexture()
    }
    
    private func redrawTexture() {
        
        guard diameter > 0 else {
            print("Diameter should be more than zero")
            texture = nil
            return
        }
        
        let scale = UIScreen.main.scale
        let needSize = CGSize(width: self.diameter, height: self.diameter)
        UIGraphicsBeginImageContextWithOptions(needSize, false, scale)
        let rectPath = UIBezierPath(ovalIn: CGRect(origin: CGPoint.zero, size: needSize))
        rectPath.addClip()
        
        if let img = image {
            img.draw(in: CGRect(origin: CGPoint.zero, size: needSize), blendMode: .normal, alpha: 1)
        } else {
            color.set()
            rectPath.fill()
        }
        
        let needImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        texture = SKTexture(image: needImage)
    }
}

//MARK: - AnalogJoystickSubstrate
open class AnalogJoystickSubstrate: AnalogJoystickComponent {
    // coming soon...
}

//MARK: - AnalogJoystickStick
open class AnalogJoystickStick: AnalogJoystickComponent {
    // coming soon...
}

//MARK: - AnalogJoystick
open class AnalogJoystick: SKNode {
    var trackingHandler: ((AnalogJoystickData) -> ())?
    var beginHandler: (() -> Void)?
    var stopHandler: (() -> Void)?
    var substrate: AnalogJoystickSubstrate!
    var stick: AnalogJoystickStick!
    private var tracking = false
    private(set) var data = AnalogJoystickData()
    
    var disabled: Bool {
        get {
            return !isUserInteractionEnabled
        }
        
        set(isDisabled) {
            isUserInteractionEnabled = !isDisabled
            
            if isDisabled {
                resetStick()
            }
        }
    }
    
    var diameter: CGFloat {
        get {
            return substrate.diameter
        }
        
        set(newDiameter) {
            stick.diameter += newDiameter - diameter
            substrate.diameter = newDiameter
        }
    }
    
    var radius: CGFloat {
        get {
            return diameter * 0.5
        }
        
        set(newRadius) {
            diameter = newRadius * 2
        }
    }
    
    init(substrate: AnalogJoystickSubstrate, stick: AnalogJoystickStick) {
        super.init()
        self.substrate = substrate
        substrate.zPosition = 0
        addChild(substrate)
        self.stick = stick
        stick.zPosition = substrate.zPosition + 1
        addChild(stick)
        disabled = false
        let velocityLoop = CADisplayLink(target: self, selector: #selector(listen))
        velocityLoop.add(to: RunLoop.current, forMode: RunLoop.Mode(rawValue: RunLoop.Mode.common.rawValue))
    }
    
    convenience init(diameters: (substrate: CGFloat, stick: CGFloat?), colors: (substrate: UIColor?, stick: UIColor?)? = nil, images: (substrate: UIImage?, stick: UIImage?)? = nil) {
        let stickDiameter = diameters.stick ?? diameters.substrate * 0.6,
        jColors = colors ?? (substrate: nil, stick: nil),
        jImages = images ?? (substrate: nil, stick: nil),
        substrate = AnalogJoystickSubstrate(diameter: diameters.substrate, color: jColors.substrate, image: jImages.substrate),
        stick = AnalogJoystickStick(diameter: stickDiameter, color: jColors.stick, image: jImages.stick)
        self.init(substrate: substrate, stick: stick)
    }
    
    convenience init(diameter: CGFloat, colors: (substrate: UIColor?, stick: UIColor?)? = nil, images: (substrate: UIImage?, stick: UIImage?)? = nil) {
        self.init(diameters: (substrate: diameter, stick: nil), colors: colors, images: images)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func listen() {
        
        if tracking {
            trackingHandler?(data)
        }
    }
    
    //MARK: - Overrides
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first, stick == atPoint(touch.location(in: self)) {
            tracking = true
            beginHandler?()
        }
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches {
            let location = touch.location(in: self)
            
            guard tracking else {
                return
            }
            
            let maxDistantion = substrate.radius,
            realDistantion = sqrt(pow(location.x, 2) + pow(location.y, 2)),
            needPosition = realDistantion <= maxDistantion ? CGPoint(x: location.x, y: location.y) : CGPoint(x: location.x / realDistantion * maxDistantion, y: location.y / realDistantion * maxDistantion)
            stick.position = needPosition
            data = AnalogJoystickData(velocity: needPosition, angular: -atan2(needPosition.x, needPosition.y))
        }
    }
    
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetStick()
    }
    
    // CustomStringConvertible protocol
    open override var description: String {
        return "AnalogJoystick(data: \(data), position: \(position))"
    }
    
    // private methods
    private func resetStick() {
        tracking = false
        let moveToBack = SKAction.move(to: CGPoint.zero, duration: TimeInterval(0.1))
        moveToBack.timingMode = .easeOut
        stick.run(moveToBack)
        data.reset()
        stopHandler?();
    }
}

typealias 🕹 = AnalogJoystick
