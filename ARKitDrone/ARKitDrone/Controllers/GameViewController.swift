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
        let view = SKView(frame: CGRect(x:60, y: UIScreen.main.bounds.height - 140, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    var ships: [Ship] = [Ship]();
    var addLinesToPlanes = false
    var addPlanesToScene = false
    var planeNodesCount = 0
    var valueReached: Bool = false
    var hit = false
    var planeHeight: CGFloat = 0.01
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    
    private lazy var padView2: SKView = {
        let view = SKView(frame: CGRect(x:620, y: UIScreen.main.bounds.height - 140, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    //    private let droneQueue = DispatchQueue(label: "com.froleeyo.dronequeue")
    
    private lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle(LocalConstants.buttonTitle, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.black)
        button.frame = CGRect(origin: CGPoint(x:630, y: UIScreen.main.bounds.height - 200), size: CGSize(width: 140, height: 40))
        button.layer.borderColor = UIColor.red.cgColor
        button.backgroundColor = UIColor.red
        button.layer.borderWidth = 3
        return button
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
        DispatchQueue.main.asyncAfter(deadline: .now() +  0.5) { [self] in
            sceneView.addSubview(padView1)
            sceneView.addSubview(padView2)
            setupPadScene()
        }
        sceneView.addSubview(armMissilesButton)
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        sceneView.isUserInteractionEnabled = true
        setupShips()
    }
    
    func setupShips() {
        let shipScene = SCNScene(named: "art.scnassets/F-35B_Lightning_II.scn")!
        // retrieve the ship node
        for i in 1...6 {
            let shipNode = shipScene.rootNode.childNode(withName: "F_35B_Lightning_II", recursively: true)!.clone()
            shipNode.simdScale = SIMD3<Float>(81.876, 81.876, 81.876)
            shipNode.name = "F_35B \(i)"
            let physicsBody =  SCNPhysicsBody(type: .kinematic, shape: nil)
            shipNode.physicsBody = physicsBody
            shipNode.physicsBody!.categoryBitMask = CollisionTypes.missile.rawValue
            shipNode.physicsBody!.contactTestBitMask = CollisionTypes.base.rawValue
            shipNode.physicsBody!.collisionBitMask = 2
            let ship = Ship(newNode: shipNode);
            sceneView.scene.rootNode.addChildNode(ship.node)
            ships.append(ship);
            ship.node.position = SCNVector3(x: Float(Int(arc4random_uniform(10)) - 5), y: Float(Int(arc4random_uniform(10)) - 5), z: 0)
            ship.node.scale = SCNVector3(x: Float(0.009), y: Float(0.009), z: Float(0.009))
//            if !ship.targetAdded {
//                let targetSceneRoot = SCNScene.nodeWithModelName(GameSceneView.targetScene)
//                ship.targetNode = targetSceneRoot.childNode(withName: GameSceneView.targetName, recursively: false)!.clone()
//                sceneView.scene.rootNode.addChildNode(ship.targetNode!)
//                ship.targetAdded = true
//            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        //        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        //        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
        //            configuration.sceneReconstruction = sceneReconstruction
        //        }
        //        configuration.frameSemantics = .sceneDepth
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: LocalConstants.environmentalMap) {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
                    sceneView.positionTank(position: SCNVector3.positionFromTransform(firstCast.worldTransform))
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
            
            if ship.targetAdded {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.001
                ship.targetNode.rotation =  SCNVector4(x: nor.x, y: nor.y, z: nor.z, w: Float(acos(angle)))
                ship.targetNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
                ship.targetNode.position = SCNVector3(x: ship.node.position.x, y: ship.node.position.y + 1, z: ship.node.position.z - 5)
                SCNTransaction.commit()
            }
        }
        if placed {
            sceneView.missileLock(target: ships[0].node)
        }
    }
    
    func keepASmallDistance(_ ship: Ship) -> SCNVector3 {
        var forceAway = SCNVector3(x: Float(0), y: Float(0), z: Float(0))
        for otherShip in ships {
            if ship.node != otherShip.node {
                if abs(otherShip.node.position.distance(ship.node.position)) < 5 {
                    forceAway = (forceAway - (otherShip.node.position - ship.node.position))
                }
            }
        }
        return forceAway
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        geometry.firstMaterial?.colorBufferWriteMask = []
        geometry.firstMaterial?.writesToDepthBuffer = true
        geometry.firstMaterial?.readsFromDepthBuffer = true
        //        if addLinesToPlanes {
        //            geometry.firstMaterial?.fillMode = .lines
        //        }
        let node = OcclusionNode(for: meshAnchor)
        node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = 5
        node.physicsBody?.collisionBitMask = 4
        node.geometry = geometry
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let meshAnchor = anchor as? ARMeshAnchor {
            let occlusionNode = OcclusionNode(for: meshAnchor)
            occlusionNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            occlusionNode.physicsBody?.isAffectedByGravity = false
            occlusionNode.physicsBody?.categoryBitMask = 5
            occlusionNode.physicsBody?.collisionBitMask = 4
            node.addChildNode(occlusionNode)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let meshAnchor = anchor as? ARMeshAnchor {
            if let occlusionNode = node.childNode(withName: "occlusion", recursively: true) as? OcclusionNode {
                occlusionNode.update(from: meshAnchor)
            }
        }
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
            sceneView.moveForward(value: (scaled * 0.5))
        } else if stickNum == 1 {
            let scaled = (yValue) * 0.05
            sceneView.changeAltitude(value: scaled)
        }
    }
    
    func tapped() {
        guard sceneView.helicopter.missilesArmed else { return }
        sceneView.toggleArmMissiles()
        let title = sceneView.missilesArmed() ? LocalConstants.disarmTitle : LocalConstants.buttonTitle
        armMissilesButton.setTitle(title, for: .normal)
        sceneView.helicopter.lockOn(ship: ships[0])
        sceneView.helicopter.lockOn(ship: ships[1])
        sceneView.helicopter.lockOn(ship: ships[2])
        sceneView.helicopter.lockOn(ship: ships[2])
        sceneView.helicopter.shootMissile()
        var count = 1
        let countlimit = 4000
        while !hit && (count < countlimit) {
            self.sceneView.helicopter.update(missile: self.sceneView.missile1, ship: self.ships[0], offset: count)
            self.sceneView.helicopter.update(missile: self.sceneView.missile2, ship: self.ships[1], offset: count)
            self.sceneView.helicopter.update(missile: self.sceneView.missile3, ship: self.ships[2], offset: count)
            self.sceneView.helicopter.update(missile: self.sceneView.missile4, ship: self.ships[3], offset: count)
            self.sceneView.helicopter.update(missile: self.sceneView.missile5, ship: self.ships[4], offset: count)
            self.sceneView.helicopter.update(missile: self.sceneView.missile6, ship: self.ships[5], offset: count)
            count += 1
            if count > 1000 {
                valueReached = true
            }
        }
    }
}
extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if valueReached {
            if (contact.nodeA.name!.contains("Missile") || contact.nodeB.name!.contains("Missile")) {
                if contact.nodeB.name!.contains("Missile") {
                   
                    var particle: SCNParticleSystem?
                    guard let particleNode = contact.nodeB.childNodes.first, let particleSystems = particleNode.particleSystems else {
                        return
                    }
                    particle = particleSystems[0]
                    particle?.birthRate = 0
                    
                    contact.nodeB.isHidden = true
                    contact.nodeB.removeFromParentNode()
                    let ship = Ship.getShip(from: contact.nodeA)
//                    ship?.targetNode.isHidden = true
//                    ship?.targetNode.removeFromParentNode()
                    
                    ship?.node.isHidden = true
                    ship?.node.removeFromParentNode()
                    sceneView.helicopter.updateHUD()
                
                    //valueReached = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
                    self.hit = true
                }
                
            }
        }
    }
}

