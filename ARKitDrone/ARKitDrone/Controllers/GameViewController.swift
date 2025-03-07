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
    
    var focusSquare: FocusSquare! = FocusSquare()
    
    var minimapScene: MinimapScene!
    
    var minimap: SKShapeNode!
    
    var playerNode: SCNNode!
    
    var score: [Int] = []
    
    let updateQueue = DispatchQueue(label: "com.arkitdrone.Queue")
    
    let coachingOverlay = ARCoachingOverlayView()
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let joystickSize = CGSize(width: 170, height: 170)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = "Models.scnassets/sharedImages/environment_blur.exr"
        static let buttonTitle = "Arm Missiles".uppercased()
        static let disarmTitle = "Disarm Missiles".uppercased()
    }
    
    // MARK: - Private Properties
    
    var autoLock = true
    
    private lazy var padView1: SKView = {
        var offset: CGFloat = 20
        if UIDevice.current.isIpad {
            offset = 220
        }
        let view = SKView(frame: CGRect(x:60, y: UIScreen.main.bounds.height - 220, width: 170, height: 170))
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
    
    lazy var minimapView: SKView = {
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
    
    lazy var armMissilesButton: UIButton = {
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
    
    lazy var destoryedText: UILabel = {
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
    
    lazy var scoreText: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.black)
        label.textColor = UIColor(red: 0.00, green: 1.00, blue: 0.01, alpha: 1.00)
        label.text = "Score: 0"
        label.backgroundColor = .black
        label.frame = CGRect(origin: CGPoint(x: 40 , y:  UIScreen.main.bounds.origin.y + 50), size: CGSize(width: 130, height: 50))
        return label
    }()
    
    var squareSet = false
    
    var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet weak var sceneView: GameSceneView!
    
    
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
        setupPlayerNode()
        
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
            setupPadScene(padView1: padView1, padView2: padView2)
            self.sceneView.scene.rootNode.addChildNode(focusSquare)
            
            //            let circle = FocusCircle()
            //            self.sceneView.scene.rootNode.addChildNode(circle)
            
        }
        sceneView.addSubview(destoryedText)
        sceneView.addSubview(armMissilesButton)
        sceneView.addSubview(scoreText)
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        sceneView.isUserInteractionEnabled = true
        
        DispatchQueue.main.async {
            self.setupCoachingOverlay()
        }
    }
    
    func setupPlayerNode() {
        playerNode = SCNNode(geometry: SCNSphere(radius: 0.01))
        playerNode.name = "Player"
        playerNode.position = SCNVector3(0, 0, 0)
        playerNode.geometry?.firstMaterial?.transparency = 0.0
        sceneView.scene.rootNode.addChildNode(playerNode)
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
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction, .stopTrackedRaycasts])
    }
    
    private func setupPadScene(padView1: SKView, padView2: SKView) {
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
        
        guard let result = sceneView.raycastQuery(
            from: tapLocation,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ) else { return }
        
        let castRay = session.raycast(result)
        
        if let firstCast = castRay.first {
            DispatchQueue.main.async {
                let tappedPosition = SCNVector3.positionFromTransform(firstCast.worldTransform)
                self.sceneView.positionTank(position: tappedPosition)
                self.cleanupFocusSquaure()
                self.game.placed = true
            }
            
        }
    }
    
    func cleanupFocusSquaure() {
        focusSquare.hide()
        focusSquare.removeAll()
        focusSquare.removeFromParentNode()
    }
}

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        sceneView.moveShips(placed: game.placed)
        if !game.placed {
            DispatchQueue.main.async {
                self.updateFocusSquare(isObjectVisible: false)
            }
        }
    }
}
