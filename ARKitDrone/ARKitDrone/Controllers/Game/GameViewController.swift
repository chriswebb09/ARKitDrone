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
import os.log

class GameViewController: UIViewController {
    
    enum SessionState {
        case setup
        case lookingForSurface
        case adjustingBoard
        case placingBoard
        case waitingForBoard
        case localizingToBoard
        case setupLevel
        case gameInProgress
    }
    
    var gameManager: GameManager? {
        didSet {
            guard let manager = gameManager else {
                sessionState = .setup
                return
            }
            if manager.isNetworked && !manager.isServer {
                sessionState = .waitingForBoard
            } else {
                sessionState = .lookingForSurface
            }
            manager.delegate = self
        }
    }
    
    var sessionState: SessionState = .setup
    
    let game = Game()
    
    var focusSquare: FocusSquare! = FocusSquare()
    
    var minimapScene: MinimapScene!
    
    var minimap: SKShapeNode!
    
    var playerNode: SCNNode!
    
    var score: [Int] = []
    
    let updateQueue = DispatchQueue(label: "com.arkitdrone.Queue", qos: .userInteractive)
    
    let coachingOverlay = ARCoachingOverlayView()
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let joystickSize = CGSize(width: 190, height: 190)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = "Models.scnassets/sharedImages/environment_blur.exr"
        static let buttonTitle = "Arm Missiles".uppercased()
        static let disarmTitle = "Disarm Missiles".uppercased()
    }
    
    // MARK: - Private Properties
    
    var autoLock = true
    
    private lazy var padView1: SKView = {
        var offset: CGFloat = 180
        var sizeOffset: CGFloat = 200
        if UIDevice.current.isIpad {
            offset = 220
            sizeOffset = 220
        }
        let frame = CGRect(x:60, y: UIScreen.main.bounds.height - offset, width: sizeOffset, height: sizeOffset)
        let view = SKView(frame:frame)
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    var missileManager: MissileManager!
    var shipManager: ShipManager!
    var addLinesToPlanes = false
    var addPlanesToScene = false
    var addsMesh = false
    var planeNodesCount = 0
    var planeHeight: CGFloat = 0.01
    var anchors = [ARAnchor]()
    var nodes = [SCNNode]()
    
    var isLoaded = false
    
    private lazy var padView2: SKView = {
        var offset: CGFloat = 180
        var sizeOffset: CGFloat = 200
        if UIDevice.current.isIpad {
            offset = 220
            sizeOffset = 220
        }
        let frame = CGRect(x:600, y: UIScreen.main.bounds.height - offset, width: sizeOffset, height: sizeOffset)
        let view = SKView(frame: frame)
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
    
    // used when state is localizingToWorldMap or localizingToSavedMap
    var targetWorldMap: ARWorldMap?
    
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
        let bounds = UIScreen.main.bounds
        let origin = CGPoint(
            x: bounds.width / 2 - 200,
            y: bounds.minY + 100
        )
        let size =  CGSize(
            width: 400,
            height: 60
        )
        label.frame = CGRect(origin: origin, size: size)
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
    
    let gameStartViewContoller = GameStartViewController()
    var overlayView: UIView?
    
    var squareSet = false
    var circle = false
    var showPhysicsShapes = false
    
    let myself = UserDefaults.standard.myself
    
    var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet weak var sceneView: GameSceneView!
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        NotificationCenter.default.addObserver(self, selector: #selector(missileCanHit), name: .missileCanHit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGameStateText), name: .updateScore, object: nil)
        missileManager = MissileManager(game: game, sceneView: sceneView)
        shipManager = ShipManager(game: game, sceneView: sceneView)
        if showPhysicsShapes {
            sceneView.debugOptions = .showPhysicsShapes
        }
        overlayView = gameStartViewContoller.view
        gameStartViewContoller.delegate = self
        view.addSubview(overlayView!)
        view.bringSubviewToFront(overlayView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    func setupViews() {
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
        //        setupPlayerNode()
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.addSubview(padView1)
        sceneView.addSubview(padView2)
        setupPadScene(padView1: padView1, padView2: padView2)
        setupCoachingOverlay()
        sceneView.addSubview(destoryedText)
        sceneView.addSubview(armMissilesButton)
        sceneView.addSubview(scoreText)
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        // guard let self = self else { return }
        self.isLoaded = true
        if UIDevice.current.userInterfaceIdiom == .phone {
            DeviceOrientation.shared.set(orientation: .landscapeRight)
        } else {
            DeviceOrientation.shared.set(orientation: .portrait)
        }
        self.focusSquare.hide()
        self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
        //        sceneView.isUserInteractionEnabled = true
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        //            guard let self = self else { return }
        //
        //            //            minimapScene = MinimapScene(size: CGSize(width: 140, height: 140))
        //            //            minimapScene.scaleMode = .resizeFill
        //            //            minimapView.presentScene(minimapScene)
        //            //            view.addSubview(minimapView)
        //            //            startMinimapUpdate()
        //
        //
        //        }
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
    
    @objc func startGame() {
        let gameSession = NetworkSession(myself: myself, asServer: true, host: myself)
        gameManager = GameManager(sceneView: sceneView, session: gameSession)
    }
    
    func updateMinimap() {
        guard let camTransform = sceneView.session.currentFrame?.camera.transform else { return }
        let camColumn = camTransform.columns
        let cameraRotation = simd_float4x4(camColumn.0, camColumn.1, camColumn.2, camColumn.3)
        let playerPosition = simd_float4(playerNode.worldPosition.x, playerNode.worldPosition.y, playerNode.worldPosition.z, 1.0)
        let shipPositions = sceneView.ships.filter { !$0.isDestroyed }.map {
            simd_float4($0.node.worldPosition.x, $0.node.worldPosition.y, $0.node.worldPosition.z, 1.0)
        }
        let missilePositions = sceneView.helicopter.missiles.filter { $0.fired && !$0.hit }.map {
            simd_float4($0.node.worldPosition.x, $0.node.worldPosition.y, $0.node.worldPosition.z, 1.0)
        }
        let heliWorldPos = sceneView.helicopterNode.worldPosition
        let heliPos: simd_float4 = game.placed ? simd_float4(heliWorldPos.x, heliWorldPos.y, heliWorldPos.z, 1.0) : simd_float4.zero
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            minimapScene.updateMinimap(
                playerPosition: playerPosition,
                helicopterPosition: heliPos,
                ships: shipPositions,
                missiles: missilePositions,
                cameraRotation: cameraRotation,
                placed: game.placed
            )
        }
    }
    
    func resetTracking() {
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
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
        session.run(
            configuration,
            options: [
                .resetTracking,
                .removeExistingAnchors,
                .resetSceneReconstruction,
                .stopTrackedRaycasts
            ]
        )
    }
    
    private func setupPadScene(padView1: SKView, padView2: SKView) {
        let scene = JoystickScene()
        scene.point = LocalConstants.joystickPoint
        scene.size = LocalConstants.joystickSize
        scene.joystickDelegate = self
        scene.stickNum = 2
        scene.scaleMode = .resizeFill
        padView1.preferredFramesPerSecond = 30
        padView1.presentScene(scene)
        padView1.ignoresSiblingOrder = true
        let scene2 = JoystickScene()
        scene2.point = LocalConstants.joystickPoint
        scene2.size = LocalConstants.joystickSize
        scene2.joystickDelegate = self
        scene2.stickNum = 1
        scene2.scaleMode = .resizeFill
        padView2.preferredFramesPerSecond = 30
        padView2.presentScene(scene2)
        padView2.ignoresSiblingOrder = true
    }
    
    // MARK: - Actions
    
    @objc func didTapUIButton() {
        updateFiredButton()
    }
    
    @objc func missileCanHit() {
        game.valueReached = true
    }
    
    func hideOverlay() {
        UIView.transition(
            with: view,
            duration: 1.0,
            options: [.transitionCrossDissolve],
            animations: {
                self.overlayView!.isHidden = true
            }) { _ in
                self.overlayView!.isUserInteractionEnabled = false
                UIApplication.shared.isIdleTimerDisabled = true
            }
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
        guard let firstCast = castRay.first else { return }
        let tappedPosition = SCNVector3.positionFromTransform(firstCast.worldTransform)
        sceneView.helicopter = sceneView.positionHelicopter(position: tappedPosition)
        let angles =  SIMD3<Float>(0, focusSquare.eulerAngles.y + 180.0 * .pi / 180, 0)
        let addNode = AddNodeAction(
            simdWorldTransform: firstCast.worldTransform,
            eulerAngles: angles
        )
        os_log(.info, "sending add node")
        gameManager?.send(addNode: addNode)
        focusSquare.cleanup()
        game.placed = true
        shipManager.setupShips()
    }
    
    func sendWorldTo(peer: Player) {
        guard let gameManager = gameManager, gameManager.isServer else {
            os_log(.error, "i'm not the server")
            return
        }
        
        switch UserDefaults.standard.boardLocatingMode {
        case .worldMap:
            os_log(.info, "generating worldmap for %s", "\(peer)")
            getCurrentWorldMapData { data, error in
                if let error = error {
                    os_log(.error, "didn't work! %s", "\(error)")
                    return
                }
                guard let data = data else {
                    os_log(.error, "no data!")
                    return
                }
                os_log(.info, "got a compressed map, sending to %s", "\(peer)")
                let location = GameBoardLocation.worldMapData(data)
                DispatchQueue.main.async {
                    os_log(.info, "sending worldmap to %s", "\(peer)")
                    gameManager.send(boardAction: .boardLocation(location), to: peer)
                }
            }
        case .manual:
            os_log(.info, "manual board location")
            gameManager.send(boardAction: .boardLocation(.manual), to: peer)
        }
    }
    
    func loadWorldMap(from archivedData: Data) {
        do {
            os_log(.info, "loading world map")
            let uncompressedData = try archivedData.decompressed()
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: uncompressedData) else {
                os_log(.error, "The WorldMap received couldn't be read")
                DispatchQueue.main.async {
                    self.sessionState = .setup
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                targetWorldMap = worldMap
                let configuration = ARWorldTrackingConfiguration()
                configuration.initialWorldMap = worldMap
                configuration.planeDetection = [.horizontal, .vertical]
                sceneView.automaticallyUpdatesLighting = false
                if let environmentMap = UIImage(named: LocalConstants.environmentalMap) {
                    sceneView.scene.lightingEnvironment.contents = environmentMap
                }
                guard let camera = self.sceneView.pointOfView?.camera else {
                    fatalError("Expected a valid `pointOfView` from the scene.")
                }
                camera.wantsHDR = true
                camera.exposureOffset = -1
                camera.minimumExposure = -1
                camera.maximumExposure = 3
                sceneView.session.run(
                    configuration,
                    options: [
                        .resetTracking,
                        .removeExistingAnchors,
                        .resetSceneReconstruction,
                        .stopTrackedRaycasts
                    ]
                )
                sceneView.debugOptions = []
                os_log(.info, "running session completed board setup")
                sceneView.scene.rootNode.addChildNode(focusSquare)
                updateFocusSquare(isObjectVisible: false)
            }
        } catch {
            os_log(.error, "The WorldMap received couldn't be decompressed")
            DispatchQueue.main.async {
                self.sessionState = .setup
            }
        }
    }
    
    func getCurrentWorldMapData(_ closure: @escaping (Data?, Error?) -> Void) {
        os_log(.info, "in getCurrentWordMapData")
        // When loading a map, send the loaded map and not the current extended map
        if let targetWorldMap = targetWorldMap {
            os_log(.info, "using existing worldmap, not asking session for a new one.")
            compressMap(map: targetWorldMap, closure)
            return
        } else {
            os_log(.info, "asking ARSession for the world map")
            sceneView.session.getCurrentWorldMap { map, error in
                os_log(.info, "ARSession getCurrentWorldMap returned")
                if let error = error {
                    os_log(.error, "didn't work! %s", "\(error)")
                    closure(nil, error)
                }
                guard let map = map else {
                    os_log(.error, "no map either!")
                    return
                }
                os_log(.info, "got a worldmap, compressing it")
                self.compressMap(map: map, closure)
            }
        }
    }
    
    private func compressMap(map: ARWorldMap, _ closure: @escaping (Data?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                os_log(.info, "data size is %d", data.count)
                let compressedData = data.compressed()
                os_log(.info, "compressed size is %d", compressedData.count)
                closure(compressedData, nil)
            } catch {
                os_log(.error, "archiving failed %s", "\(error)")
                closure(nil, error)
            }
        }
    }
}
