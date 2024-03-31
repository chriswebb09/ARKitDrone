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
    
    struct ColliderCategory {
        static let tank = 1 << 0
        static let shell = 1 << 1
        static let ground = 1 << 2
        static let helicopter = 1 << 3
        static let missile = 1 << 4
        static let wall = 1 << 5
    }
    
    var placed: Bool = false
    
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
        let view = SKView(frame: CGRect(x:60, y: UIScreen.main.bounds.height - offset, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    var planeNodesCount = 0
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
        sceneView.positionHUD()
        sceneView.addSubview(armMissilesButton)
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        sceneView.isUserInteractionEnabled = true
        
    }
    
    // MARK: - Private Methods
    
    private func setupTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
            configuration.sceneReconstruction = sceneReconstruction
        }
        configuration.frameSemantics = .sceneDepth
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
            let result = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
            let castRay =  session.raycast(result!)
            sceneView.positionTank(position: SCNVector3.positionFromTransform(castRay.first!.worldTransform))
            placed = true
        }
    }
}

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        geometry.firstMaterial?.colorBufferWriteMask = []
        geometry.firstMaterial?.writesToDepthBuffer = true
        geometry.firstMaterial?.readsFromDepthBuffer = true
        //        geometry.firstMaterial?.fillMode = .lines
        let node = OcclusionNode(for: meshAnchor)
        node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        node.physicsBody?.isAffectedByGravity = false
        node.physicsBody?.categoryBitMask = 5
        node.physicsBody?.collisionBitMask = 4
        node.geometry = geometry
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //        if let planeAnchor = anchor as? ARPlaneAnchor {
        //            let plane = self.scanState.addPlane(from: planeAnchor)
        //
        //            if plane.shouldBeTreatedAsWall() {
        //                self.wallNode?.addPlane(planeAnchor)
        //            }
        //        }
        
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
        //        if let planeAnchor = anchor as? ARPlaneAnchor {
        //            let plane = self.scanState.updatePlane(from: planeAnchor)
        //
        //            if plane.shouldBeTreatedAsWall() {
        //                self.wallNode?.updatePlane(planeAnchor)
        //            } else {
        //                self.wallNode?.removePlane(withID: plane.id)
        //            }
        //        }
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
        if stickNum == 1 {
            let scaled = (yValue)
            sceneView.moveForward(value: (scaled * 0.5))
        } else if stickNum == 2 {
            let scaled = (yValue) * 0.05
            sceneView.changeAltitude(value: scaled)
        }
    }
    
    func tapped() {
        sceneView.shootMissile()
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        print(contact)
        dump(contact)
        if contact.nodeB.physicsBody?.contactTestBitMask == 0 {
            print("NodeB has mask = 0")
        } else if contact.nodeB.physicsBody?.contactTestBitMask == 1 {
            print("NodeB has mask = 1")
        }
        if contact.nodeB.physicsBody?.contactTestBitMask == 2 {
            print("NodeB has mask = 2")
        } else if contact.nodeB.physicsBody?.contactTestBitMask == 3 {
            print("NodeB has mask = 1")
        }
    }
}
