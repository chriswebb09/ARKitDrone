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
    
    var placed: Bool = false
    var running = false
    var minimapScene: MinimapScene!
    var score: Int = 0
    var currentMissile: Missile!
    
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
        let view = SKView(frame: CGRect(x:60, y: UIScreen.main.bounds.height - 220, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    var ships: [Ship] = [Ship]();
    var addLinesToPlanes = false
    var addPlanesToScene = false
    var planeNodesCount = 0
    var valueReached: Bool = false
    //    var hit = false
    var planeHeight: CGFloat = 0.01
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    var scoreUpdated = false
    var minimap: SKShapeNode!
    var playerNode: SCNNode!
    
    private lazy var padView2: SKView = {
        let view = SKView(frame: CGRect(x:600, y: UIScreen.main.bounds.height - 220, width: 160, height: 140))
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
        button.layer.borderColor = UIColor(red: 0.95, green: 0.15, blue: 0.07, alpha: 1.00).cgColor
        button.backgroundColor = UIColor(red: 0.95, green: 0.15, blue: 0.07, alpha: 1.00)
        button.layer.borderWidth = 3
        return button
    }()
    
    private lazy var destoryedText: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor(red:1.0, green: 0, blue: 0.01, alpha: 1.00)
        label.backgroundColor = .clear
        label.font = UIFont(name: "Avenir-Black", size: 40)
        label.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width / 2 - 200, y:  UIScreen.main.bounds.origin.y + 100), size: CGSize(width: 400, height: 60))
        return label
    }()
    
    private lazy var scoreText: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont(name: "Avenir-Black", size: 24)
        label.textColor = UIColor(red: 0.00, green: 1.00, blue: 0.01, alpha: 1.00)
        label.text = "Score: 0"
        label.backgroundColor = .clear
        label.frame = CGRect(origin: CGPoint(x: 40 , y:  UIScreen.main.bounds.origin.y + 50), size: CGSize(width: 300, height: 40))
        //        label.setshadow()
        return label
    }()
    
    private var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet private weak var sceneView: GameSceneView!
    
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
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        UIApplication.shared.isIdleTimerDisabled = true
        setupTracking()
        sceneView.setup()
        sceneView.scene.physicsWorld.contactDelegate = self
        playerNode = SCNNode(geometry: SCNSphere(radius: 0.5))
        playerNode.name = "Player"
        playerNode.position = SCNVector3(0, 0, 0)  // Center
        sceneView.scene.rootNode.addChildNode(playerNode)
        DispatchQueue.main.asyncAfter(deadline: .now() +  0.5) { [self] in
            sceneView.addSubview(padView1)
            sceneView.addSubview(padView2)
            minimapScene = MinimapScene(size: CGSize(width: 140, height: 140))
            minimapScene.scaleMode = .resizeFill
            minimapView.presentScene(minimapScene)
            self.view.addSubview(minimapView)
            startMinimapUpdate()
            setupPadScene()
        }
        sceneView.addSubview(destoryedText)
        sceneView.addSubview(armMissilesButton)
        sceneView.addSubview(scoreText)
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        sceneView.isUserInteractionEnabled = true
        setupShips()
        
    }
    
    func setupShips() {
        let shipScene = SCNScene(named: "art.scnassets/F-35B_Lightning_II.scn")!
        // retrieve the ship node
        for i in 1...8 {
            let shipNode = shipScene.rootNode.childNode(withName: "F_35B_Lightning_II", recursively: true)!.clone()
            shipNode.name = "F_35B \(i)"
            let physicsBody =  SCNPhysicsBody(type: .kinematic, shape: nil)
            shipNode.physicsBody = physicsBody
            shipNode.physicsBody!.categoryBitMask = CollisionTypes.missile.rawValue
            shipNode.physicsBody!.contactTestBitMask = CollisionTypes.base.rawValue
            shipNode.physicsBody!.collisionBitMask = 2
            let ship = Ship(newNode: shipNode)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                sceneView.scene.rootNode.addChildNode(ship.node)
                ships.append(ship)
                ship.node.position = SCNVector3(x: Float(Int(arc4random_uniform(10)) - 5), y: Float(Int(arc4random_uniform(10)) - 5), z: -15)
                ship.node.scale = SCNVector3(x: Float(0.006), y: Float(0.006), z: Float(0.006))
            }
        }
    }
    
    // MARK: - Private Methods
    
    func startMinimapUpdate() {
        let updateAction = SKAction.run { [weak self] in
            self?.updateMinimap()
        }
        let delay = SKAction.wait(forDuration: 0.1)
        let updateLoop = SKAction.sequence([updateAction, delay])
        minimapScene.run(SKAction.repeatForever(updateLoop))
    }
    
    func updateMinimap() {
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        guard cameraTransform != nil else { return }
        let cameraRotation = simd_float4x4(cameraTransform!.columns.0, cameraTransform!.columns.1, cameraTransform!.columns.2, cameraTransform!.columns.3)
        let playerPositionSIMD = simd_float4(playerNode.worldPosition.x, playerNode.worldPosition.y, playerNode.worldPosition.z, 1.0)
        let shipPositionsSIMD = ships.filter { !$0.isDestroyed }.map { simd_float4($0.node.worldPosition.x, $0.node.worldPosition.y, $0.node.worldPosition.z, 1.0) }
        minimapScene.updateMinimap(playerPosition: playerPositionSIMD, ships: shipPositionsSIMD, cameraRotation: cameraRotation)
    }
    
    private func setupTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .horizontal]
        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
            configuration.sceneReconstruction = sceneReconstruction
        }
        configuration.frameSemantics = .sceneDepth
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: LocalConstants.environmentalMap) {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction, .stopTrackedRaycasts])
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
        sceneView.toggleArmMissiles()
        let title = sceneView.missilesArmed() ? LocalConstants.disarmTitle : LocalConstants.buttonTitle
        armMissilesButton.setTitle(title, for: .normal)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !placed {
            let tapLocation: CGPoint = touches.first!.location(in: sceneView)
            if let result = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal) {
                let castRay =  session.raycast(result)
                if let firstCast = castRay.first {
                    DispatchQueue.global(qos: .background).async {
                        self.sceneView.positionTank(position: SCNVector3.positionFromTransform(firstCast.worldTransform))
                        DispatchQueue.main.async {
                            //                            self.sceneView.helicopterNode.scale = SCNVector3(x: -0.001, y: -0.001, z: -0.001)
                            //                            self.sceneView.helicopter.helicopterNode.scale = SCNVector3(x: -0.001, y: -0.001, z: -0.001)
                        }
                    }
                    placed = true
                }
            }
        }
    }
}

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        var percievedCenter = SCNVector3(x: Float(0), y: Float(0), z:Float(0))
        var percievedVelocity = SCNVector3(x: Float(0), y: Float(0), z:Float(0))
        for otherShip in ships {
            percievedCenter = percievedCenter + otherShip.node.position;
            percievedVelocity = percievedVelocity + (otherShip.velocity);
        }
        for ship in ships {
            var v1 = ship.flyCenterOfMass(ships.count, percievedCenter)
            var v2 = keepASmallDistance(ship)
            var v3 = ship.matchSpeedWithOtherShips(ships.count, percievedVelocity)
            var v4 = ship.boundPositions()
            v1 *= (0.01)
            v2 *= (0.01)
            v3 *= (0.01)
            v4 *= (1.0)
            let forward = SCNVector3(x: Float(0), y: Float(0), z: Float(1))
            let velocityNormal = ship.velocity.normalized()
            ship.velocity = ship.velocity + v1 + v2 + v3 + v4;
            ship.limitVelocity()
            let nor = forward.cross(velocityNormal)
            let angle = CGFloat(forward.dot(velocityNormal))
            ship.node.rotation = SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: Float(acos(angle)))
            ship.node.position = ship.node.position + (ship.velocity)
            //            if ship.targetAdded {
            //                SCNTransaction.begin()
            //                SCNTransaction.animationDuration = 0.001
            //                ship.targetNode.rotation =  SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: Float(acos(angle)))
            //                ship.targetNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            //                ship.targetNode.position = SCNVector3(x: ship.node.position.x, y: ship.node.position.y + 1, z: ship.node.position.z - 10)
            //                SCNTransaction.commit()
            //            }
        }
        if placed {
            sceneView.missileLock(target: ships[0].node)
        }
    }
    
    func keepASmallDistance(_ ship: Ship) -> SCNVector3 {
        var forceAway = SCNVector3(x: Float(0), y: Float(0), z: Float(0))
        for otherShip in ships {
            if ship.node != otherShip.node {
                if abs(otherShip.node.position.distance(ship.node.position)) < 4 {
                    forceAway = (forceAway - (otherShip.node.position - ship.node.position))
                }
            }
        }
        return forceAway
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
        sceneView.toggleArmMissiles()
        fire()
    }
    
    func fire() {
        guard sceneView.missiles.isEmpty == false else { return }
        let ship = ships.filter { $0.isDestroyed == false }.first
        //        sceneView.helicopter.lockOn(ship:  ship!)
        let missile = sceneView.missiles.removeFirst()
        guard missile.hit == false else { return }
        currentMissile = missile
        sceneView.helicopter.lockOn(ship: ship!)
        valueReached = false
        // hit = false
        print("Missile \(missile.num)")
        var count = 1
        //        let countlimit = 5000
        while !missile.hit {
            self.sceneView.helicopter.update(missile: missile, ship: ship!, offset: count)
            count += 1
            if count > 3000 {
                valueReached = true
            }
            if missile.hit {
                missile.particle?.birthRate = 0
                missile.exhaustNode.removeFromParentNode()
                return
            }
        }
        //        hit = false
        sceneView.toggleArmMissiles()
    }
}
extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if valueReached {
            if (contact.nodeA.name!.contains("Missile") || contact.nodeB.name!.contains("Missile")) {
                if ((contact.nodeA.name!.contains("Missile") && !contact.nodeB.name!.contains("Missile")) || (contact.nodeB.name!.contains("Missile") && !contact.nodeA.name!.contains("Missile")) ) {
                    
                    if !self.scoreUpdated {
                        DispatchQueue.main.async {
                            self.scoreUpdated = true
                            self.score += 1
                            self.destoryedText.text = "Enemy Destroyed!"
                            self.scoreText.text = "Score \(self.score)"
                        }
                    } else {
                        return
                    }
                    
                    if contact.nodeB.name!.contains("Missile") {
                        
                        var particle: SCNParticleSystem?
                        guard let particleNode = contact.nodeB.childNodes.first, let particleSystems = particleNode.particleSystems else {
                            return
                        }
                        particle = particleSystems[0]
                        particle?.birthRate = 0
                        
                        let explosion = SCNParticleSystem.createExplosion()
                        let explosionNode = SCNNode()
                        explosionNode.position = contact.contactPoint
                        explosionNode.addParticleSystem(explosion)
                        sceneView.scene.rootNode.addChildNode(explosionNode)
                        
                        explosionNode.runAction(SCNAction.sequence([
                            SCNAction.wait(duration: 0.25),  // Wait for explosion effect to finish
                            SCNAction.removeFromParentNode() // Remove explosion node from the scene
                        ]))
                        
                        contact.nodeB.isHidden = true
                        contact.nodeB.removeFromParentNode()
                        DispatchQueue.main.async {
                            let ship = Ship.getShip(from: contact.nodeA)!
                            ship.isDestroyed = true
                            ship.node.isHidden = true
                            ship.node.removeFromParentNode()
                            self.currentMissile.hit = true
                        }
                        sceneView.helicopter.updateHUD()
                        if ships.filter { !$0.isDestroyed }.count == 0 {
                            explosionNode.particleSystems![0].birthRate = 0
                            explosion.birthRate = 0
                            explosion.removeAllAnimations()
                            explosionNode.removeFromParentNode()
                            explosionNode.isHidden = true
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                explosionNode.particleSystems![0].birthRate = 0
                                explosion.birthRate = 0
                                explosion.removeAllAnimations()
                                explosionNode.removeFromParentNode()
                                explosionNode.isHidden = true
                            }
                        }
                    }
                    //                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    //                    self.destoryedText.text = ""
                    //                }
                } else {
                    var particle: SCNParticleSystem?
                    guard let particleNode = contact.nodeA.childNodes.first, let particleSystems = particleNode.particleSystems else {
                        return
                    }
                    
                    particle = particleSystems[0]
                    particle?.birthRate = 0
                    
                    DispatchQueue.main.async {
                        let ship = Ship.getShip(from: contact.nodeB)!
                        ship.isDestroyed = true
                        ship.node.isHidden = true
                        ship.node.removeFromParentNode()
                        //                        self.hit = true
                        self.currentMissile.hit = true
                    }
                    
                    let explosion = SCNParticleSystem.createExplosion()
                    let explosionNode = SCNNode()
                    explosionNode.position = contact.contactPoint
                    explosionNode.addParticleSystem(explosion)
                    sceneView.scene.rootNode.addChildNode(explosionNode)
                    
                    explosionNode.runAction(SCNAction.sequence([
                        SCNAction.wait(duration: 0.25),  // Wait for explosion effect to finish
                        SCNAction.removeFromParentNode() // Remove explosion node from the scene
                    ]))
                    
                    contact.nodeA.isHidden = true
                    contact.nodeA.removeFromParentNode()
                    
                    sceneView.helicopter.updateHUD()
                    
                    if ships.filter { !$0.isDestroyed }.count == 0 {
                        explosionNode.particleSystems![0].birthRate = 0
                        explosion.birthRate = 0
                        explosion.removeAllAnimations()
                        explosionNode.removeFromParentNode()
                        explosionNode.isHidden = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            explosionNode.particleSystems![0].birthRate = 0
                            explosion.birthRate = 0
                            explosion.removeAllAnimations()
                            explosionNode.removeFromParentNode()
                            explosionNode.isHidden = true
                        }
                    }
                }
            }
            if currentMissile.hit {
                self.scoreUpdated = false
                currentMissile = nil
            }
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            //                self.scoreUpdated = false
            //
            //            }
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            //                self.destoryedText.text = ""
            //                self.hit = false
            //            }
        }
    }
}

