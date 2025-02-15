//
//  ViewController.swift
//  ARKitDrone
//
//  Created by Christopher Webb-Orenstein on 10/7/17.
//  Copyright © 2017 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import SpriteKit

class GameViewController: UIViewController {
    
    let game = Game()
    var minimapScene: MinimapScene!
    var minimap: SKShapeNode!
    var playerNode: SCNNode!
    var score: [Int] = []
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let joystickSize = CGSize(width: 160, height: 150)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = "Models.scnassets/sharedImages/environment_blur.exr"
        static let buttonTitle = "Arm Missiles".uppercased()
        static let disarmTitle = "Disarm Missiles".uppercased()
    }
    
    // MARK: - Private Properties
    
    private lazy var padView1: SKView = {
        var offset: CGFloat = 20
        if UIDevice.current.isIpad {
            offset = 220
        }
        let view = SKView(frame: CGRect(x:60, y: UIScreen.main.bounds.height - 220, width:170, height: 170))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    var addLinesToPlanes = false
    var addPlanesToScene = false
    var addsMesh = false
    var planeNodesCount = 0
    var planeHeight: CGFloat = 0.01
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    
    private lazy var padView2: SKView = {
        let view = SKView(frame: CGRect(x:600, y: UIScreen.main.bounds.height - 220, width: 170, height: 170))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var minimapView: SKView = {
        let size: CGFloat = 140
        let view = SKView(frame: CGRect(
            x: UIScreen.main.bounds.width - size - 20,
            y: 20,
            width: size,
            height: size
        ))
        view.isMultipleTouchEnabled = false
        view.backgroundColor = .clear
        return view
    }()
    
    //    private let droneQueue = DispatchQueue(label: "com.froleeyo.dronequeue")
    
    private lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle(LocalConstants.buttonTitle, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.black)
        button.frame = CGRect(origin: CGPoint(x:600, y: UIScreen.main.bounds.height - 320), size: CGSize(width: 180, height: 50))
        button.layer.borderColor = UIColor(red: 1.00, green: 0.03, blue: 0.00, alpha: 1.00).cgColor
        //UIColor(red: 0.95, green: 0.15, blue: 0.07, alpha: 1.00).cgColor
        button.backgroundColor = UIColor(red: 1.00, green: 0.03, blue: 0.00, alpha: 1.00)
        button.layer.borderWidth = 3
        return button
    }()
    
    private lazy var destoryedText: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor(red: 1.00, green: 0.03, blue: 0.00, alpha: 1.00)
        label.backgroundColor = .clear
        label.font = UIFont(
            name: "AvenirNext-Bold",
            size: 30
        )
        label.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width / 2 - 200, y:  UIScreen.main.bounds.origin.y + 100), size: CGSize(width: 400, height: 60))
        return label
    }()
    
    private lazy var scoreText: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.black)
        label.textColor = UIColor(red: 0.00, green: 1.00, blue: 0.01, alpha: 1.00)
        label.text = "Score: 0"
        label.backgroundColor = .black
        label.frame = CGRect(origin: CGPoint(x: 40 , y:  UIScreen.main.bounds.origin.y + 50), size: CGSize(width: 130, height: 50))
        return label
    }()
    
    private var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet private weak var sceneView: GameSceneView!
    
    private var activeMissileTrackers: [String: MissileTrackingInfo] = [:]
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        //        sceneView.debugOptions = .showPhysicsShapes
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupViews()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setupViews() {
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            DeviceOrientation.shared.set(orientation: .landscapeRight)
        } else {
            DeviceOrientation.shared.set(orientation: .portrait)
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupTracking()
        sceneView.setup()
        
        sceneView.scene.physicsWorld.contactDelegate = self
        
        playerNode = SCNNode(geometry: SCNSphere(radius: 0.5))
        playerNode.name = "Player"
        playerNode.position = SCNVector3(0, 0, 0)
        
        sceneView.scene.rootNode.addChildNode(playerNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() +  0.5) { [weak self] in
            guard let self = self else { return }
            sceneView.addSubview(padView1)
            sceneView.addSubview(padView2)
            sceneView.setupShips()
            minimapScene = MinimapScene(size: CGSize(width: 140, height: 140))
            minimapScene.scaleMode = .resizeFill
            minimapView.presentScene(minimapScene)
            view.addSubview(minimapView)
            startMinimapUpdate()
            setupPadScene()
            
        }
        sceneView.addSubview(destoryedText)
        sceneView.addSubview(armMissilesButton)
        sceneView.addSubview(scoreText)
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        sceneView.isUserInteractionEnabled = true
    }
    
    // MARK: - Private Methods
    
    func startMinimapUpdate() {
        let updateAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            updateMinimap()
        }
        let delay = SKAction.wait(forDuration: 0.1)
        let updateLoop = SKAction.sequence([updateAction, delay])
        minimapScene.run(SKAction.repeatForever(updateLoop))
    }
    
    func updateMinimap() {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
        let cameraRotation = simd_float4x4(cameraTransform.columns.0, cameraTransform.columns.1, cameraTransform.columns.2, cameraTransform.columns.3)
        let playerPosition = simd_float4(playerNode.worldPosition.x, playerNode.worldPosition.y, playerNode.worldPosition.z, 1.0)
        let shipPositions = sceneView.ships.filter { !$0.isDestroyed }.map { simd_float4($0.node.worldPosition.x, $0.node.worldPosition.y, $0.node.worldPosition.z, 1.0) }
        let missilePositions = sceneView.missiles.filter { $0.fired && !$0.hit }.map { simd_float4($0.node.worldPosition.x, $0.node.worldPosition.y, $0.node.worldPosition.z, 1.0) }
        let helcopterWorldPosition = sceneView.helicopterNode.worldPosition
        let helicopterPosition: simd_float4 = game.placed ? simd_float4(helcopterWorldPosition.x, helcopterWorldPosition.y, helcopterWorldPosition.z, 1.0) : simd_float4.zero
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            minimapScene.updateMinimap(
                playerPosition: playerPosition,
                helicopterPosition: helicopterPosition,
                ships: shipPositions,
                missiles: missilePositions,
                cameraRotation: cameraRotation,
                placed: game.placed
            )
        }
    }
    
    private func setupTracking() {
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.horizontal]
        
        if addsMesh {
            let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
                configuration.sceneReconstruction = sceneReconstruction
            }
            configuration.frameSemantics = .sceneDepth
        }
        
        
        sceneView.automaticallyUpdatesLighting = false
        
        if let environmentMap = UIImage(named: LocalConstants.environmentalMap) {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        
        session.run(configuration,
                    options: [
                        .resetTracking,
                        .removeExistingAnchors,
                        .resetSceneReconstruction,
                        .stopTrackedRaycasts
                    ])
    }
    
    private func setupPadScene() {
        let scene = JoystickScene()
        scene.point = LocalConstants.joystickPoint
        scene.size = LocalConstants.joystickSize
        scene.joystickDelegate = self
        scene.stickNum = 2
        padView1.presentScene(scene)
        padView1.ignoresSiblingOrder = true
        
        let scene2 = JoystickScene()
        scene2.point = LocalConstants.joystickPoint
        scene2.size = LocalConstants.joystickSize
        scene2.joystickDelegate = self
        scene2.stickNum = 1
        padView2.presentScene(scene2)
        padView2.ignoresSiblingOrder = true
    }
    
    // MARK: - Actions
    
    @objc func didTapUIButton() {
        updateFiredButton()
    }
    
    func updateFiredButton() {
        sceneView.helicopter.missilesArmed = !sceneView.helicopter.missilesArmed
        let title = sceneView.helicopter.missilesAreArmed() ? LocalConstants.disarmTitle : LocalConstants.buttonTitle
        armMissilesButton.setTitle(title, for: .normal)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !game.placed, let touch = touches.first else { return }
        let tapLocation: CGPoint = touch.location(in: sceneView)
        guard let result = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal) else { return }
        let castRay = session.raycast(result)
        if let firstCast = castRay.first {
            let tappedPosition = SCNVector3.positionFromTransform(firstCast.worldTransform)
            sceneView.positionTank(position: tappedPosition)
            game.placed = true
        }
    }
}

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        sceneView.moveShips()
    }
    
}

// MARK: - JoystickSceneDelegate

extension GameViewController: JoystickSceneDelegate {
    
    func update(xValue: Float, stickNum: Int) {
        if stickNum == 1 {
            let scaled = (xValue) * 0.0005
            sceneView.rotate(value: scaled)
        } else if stickNum == 2 {
            let scaled = (xValue) * 0.05
            sceneView.moveSides(value: -scaled)
        }
    }
    
    func update(yValue: Float, stickNum: Int) {
        if stickNum == 2 {
            let scaled = (yValue)
            sceneView.moveForward(value: (scaled * 0.009))
        } else if stickNum == 1 {
            let scaled = (yValue) * 0.01
            sceneView.changeAltitude(value: scaled)
        }
    }
    
    func tapped() {
        guard sceneView.helicopter.missilesArmed else { return }
        fire()
    }
    
    func fire() {
        guard !sceneView.missiles.isEmpty, !game.scoreUpdated else { return }
        guard let ship = sceneView.ships.first(where: { !$0.isDestroyed && !$0.targeted }) else { return }
        ship.targeted = true
        
        guard let missile = sceneView.missiles.first(where:{ !$0.fired }) else { return }
        
        missile.fired = true
        
        game.valueReached = false
        missile.addCollision()
        sceneView.missileLock(ship: ship)
        missile.node.look(at: ship.node.position)
        ApacheHelicopter.speed = 0
        
        let targetPos = ship.node.presentation.simdWorldPosition
        let currentPos = missile.node.presentation.simdWorldPosition
        let direction = simd_normalize(targetPos - currentPos)
        
        missile.particle?.orientationDirection = SCNVector3(-direction.x, -direction.y, -direction.z)
        missile.particle?.birthRate = 1000
        
        let displayLink = CADisplayLink(target: self, selector: #selector(updateMissilePosition))
        displayLink.preferredFramesPerSecond = 60
        
        activeMissileTrackers[missile.id] = MissileTrackingInfo(
            missile: missile,
            target: ship,
            startTime: CACurrentMediaTime(),
            displayLink: displayLink,
            lastUpdateTime: CACurrentMediaTime()
        )
        displayLink.add(to: .main, forMode: .common)
    }
    
    private struct MissileTrackingInfo {
        let missile: Missile
        let target: Ship
        let startTime: CFTimeInterval
        let displayLink: CADisplayLink
        var frameCount: Int = 0
        var lastUpdateTime: CFTimeInterval
    }
    
    @objc private func updateMissilePosition(displayLink: CADisplayLink) {
        guard let trackingInfo = activeMissileTrackers.first(where: { $0.value.displayLink === displayLink })?.value else {
            displayLink.invalidate()
            return
        }
        let missile = trackingInfo.missile
        let ship = trackingInfo.target
        if missile.hit {
            displayLink.invalidate()
            activeMissileTrackers[missile.id] = nil
            return
        }
        let deltaTime = displayLink.timestamp - trackingInfo.lastUpdateTime
        let speed: Float = 50
        let targetPos = ship.node.presentation.simdWorldPosition
        let currentPos = missile.node.presentation.simdWorldPosition
        let direction = simd_normalize(targetPos - currentPos)
        let movement = direction * speed * Float(deltaTime)
        missile.node.simdWorldPosition += movement
        missile.node.look(at: ship.node.presentation.position)
        missile.particle?.orientationDirection = SCNVector3(-direction.x, -direction.y, -direction.z)
        var updatedInfo = trackingInfo
        updatedInfo.frameCount += 1
        updatedInfo.lastUpdateTime = displayLink.timestamp
        activeMissileTrackers[missile.id] = updatedInfo
        game.valueReached = updatedInfo.frameCount > 50
    }
    
}

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        let conditionOne = (contact.nodeA.name!.contains("Missile") && !contact.nodeB.name!.contains("Missile"))
        let conditionTwo = (contact.nodeB.name!.contains("Missile") && !contact.nodeA.name!.contains("Missile"))
        
        if (game.valueReached && (conditionOne || conditionTwo) && !self.game.scoreUpdated) {
            let conditionalShipNode: SCNNode! = conditionOne ? contact.nodeB : contact.nodeA
            let conditionalMissileNode: SCNNode! = conditionOne ? contact.nodeA : contact.nodeB
            let tempMissile = Missile.getMissile(from: conditionalMissileNode)!
            let canUpdateScore = tempMissile.hit == false
            tempMissile.hit = true
            if canUpdateScore{
                DispatchQueue.main.async {
                    //                    self.game.playerScore = -(self.sceneView.missiles.filter { !$0.hit }.count - 8)
                    self.game.playerScore += 1
                    ApacheHelicopter.speed = 0
                    self.game.updateScoreText()
                    self.destoryedText.fadeTransition(0.001)
                    self.scoreText.fadeTransition(0.001)
                    self.destoryedText.text = self.game.destoryedTextString
                    self.scoreText.text = self.game.scoreTextString
                }
            }
            
            tempMissile.particle?.birthRate = 0
            tempMissile.node.removeAll()
            let flash = SCNLight()
            flash.type = .omni
            flash.color = UIColor.white
            flash.intensity = 4000
            flash.attenuationStartDistance = 5
            flash.attenuationEndDistance = 15  // Ensures the light fades over distance
            let flashNode = SCNNode()
            flashNode.light = flash
            flashNode.position = contact.contactPoint // Set this to the explosion's position
            sceneView.scene.rootNode.addChildNode(flashNode)
            let fadeAction = SCNAction.customAction(duration: 0.3) { (node, elapsedTime) in
                let percent = 1.0 - (elapsedTime / 0.3)
                node.light?.intensity = 4000 * percent
            }
            let removeAction = SCNAction.sequence([fadeAction, SCNAction.removeFromParentNode()])
            flashNode.runAction(removeAction)
            flashNode.runAction(SCNAction.sequence([
                SCNAction.wait(duration: 0.25),
                SCNAction.removeFromParentNode()
            ]))
            sceneView.addExplosion(contactPoint: contact.contactPoint)
            DispatchQueue.main.async {
                self.sceneView.positionHUD()
                self.sceneView.helicopter.hud.localTranslate(by: SCNVector3(x: 0, y: 0, z: -0.18))
                let ship = Ship.getShip(from: conditionalShipNode)!
                ship.isDestroyed = true
                ship.node.isHidden = true
                ship.node.removeFromParentNode()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                self.game.scoreUpdated = false
                self.armMissilesButton.isEnabled = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                self.game.playerScore = -(self.sceneView.missiles.count - 8)
                self.game.destoryedTextString = ""
                self.destoryedText.text = self.game.destoryedTextString
                self.destoryedText.fadeTransition(0.001)
            }
        }
    }
}
