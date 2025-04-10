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
    
    let gameStartViewContoller = GameStartViewController()
    var overlayView: UIView?
    
    var squareSet = false
    var circle = false
    
    private let myself = UserDefaults.standard.myself
    
    var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet weak var sceneView: GameSceneView!
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        NotificationCenter.default.addObserver(self, selector: #selector(missileCanHit), name: .missileCanHit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateGameStateText), name: .updateScore, object: nil)
        missileManager = MissileManager(game: game, sceneView: sceneView)
        shipManager = ShipManager(game: game, sceneView: sceneView)
        //        sceneView.debugOptions = .showPhysicsShapes
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overlayView = gameStartViewContoller.view
        gameStartViewContoller.delegate = self
        view.addSubview(overlayView!)
        view.bringSubviewToFront(overlayView!)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            shipManager.setupShips()
            minimapScene = MinimapScene(size: CGSize(width: 140, height: 140))
            minimapScene.scaleMode = .resizeFill
            minimapView.presentScene(minimapScene)
            view.addSubview(minimapView)
            startMinimapUpdate()
            setupCoachingOverlay()
            sceneView.addSubview(destoryedText)
            sceneView.addSubview(armMissilesButton)
            sceneView.addSubview(scoreText)
            armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
            sceneView.isUserInteractionEnabled = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                sceneView.addSubview(padView1)
                sceneView.addSubview(padView2)
                setupPadScene(padView1: padView1, padView2: padView2)
                if self.circle {
                    let focusCircle = FocusCircle()
                    sceneView.scene.rootNode.addChildNode(focusCircle)
                } else {
                    sceneView.scene.rootNode.addChildNode(focusSquare)
                    updateFocusSquare(isObjectVisible: true)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                self.isLoaded = true
            }
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
    
    @objc func startGame() {
        let gameSession = NetworkSession(myself: myself, asServer: true, host: myself)
        self.gameManager = GameManager(sceneView: sceneView, session: gameSession)
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
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
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
    
    @objc func missileCanHit() {
        game.valueReached = true
    }
    
    func hideOverlay() {
        UIView.transition(with: view, duration: 1.0, options: [.transitionCrossDissolve], animations: {
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let tappedPosition = SCNVector3.positionFromTransform(firstCast.worldTransform)
            sceneView.positionTank(position: tappedPosition)
            focusSquare.cleanup()
            game.placed = true
        }
    }
    
    private func process(boardAction: BoardSetupAction, from peer: Player) {
        switch boardAction {
        case .boardLocation(let location):
            switch location {
            case .worldMapData(let data):
               // os_log(.info, "Received WorldMap data. Size: %d", data.count)
                loadWorldMap(from: data)
            case .manual:
                //os_log(.info, "Received a manual board placement")
                sessionState = .lookingForSurface
            }
        case .requestBoardLocation:
            sendWorldTo(peer: peer)
        }
    }
    
    
    func sendWorldTo(peer: Player) {
        guard let gameManager = gameManager, gameManager.isServer else {
            print("not the server")
            return
        }
            
            //os_log(.error, "i'm not the server"); return }
        
        switch UserDefaults.standard.boardLocatingMode {
        case .worldMap:
//            os_log(.info, "generating worldmap for %s", "\(peer)")
            getCurrentWorldMapData { data, error in
                if let error = error {
//                    os_log(.error, "didn't work! %s", "\(error)")
                    return
                }
                guard let data = data else {
                    return
                }
                
//                os_log(.error, "no data!"); return }
//                os_log(.info, "got a compressed map, sending to %s", "\(peer)")
                let location = GameBoardLocation.worldMapData(data)
                DispatchQueue.main.async {
//                    os_log(.info, "sending worldmap to %s", "\(peer)")
                    gameManager.send(boardAction: .boardLocation(location), to: peer)
                }
            }
        case .manual:
            gameManager.send(boardAction: .boardLocation(.manual), to: peer)
        }
    }
    
    func loadWorldMap(from archivedData: Data) {
        do {
            let uncompressedData = try archivedData.decompressed()
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: uncompressedData) else {
//                os_log(.error, "The WorldMap received couldn't be read")
                DispatchQueue.main.async {
//                    self.showAlert(title: "An error occured while loading the WorldMap (Failed to read)")
                    self.sessionState = .setup
                }
                return
            }
            
            DispatchQueue.main.async {
                self.targetWorldMap = worldMap
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                
                self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                
                self.sessionState = .localizingToBoard
            }
        } catch {
//            os_log(.error, "The WorldMap received couldn't be decompressed")
            DispatchQueue.main.async {
//                self.showAlert(title: "An error occured while loading the WorldMap (Failed to decompress)")
                self.sessionState = .setup
            }
        }
    }
    
    func getCurrentWorldMapData(_ closure: @escaping (Data?, Error?) -> Void) {
//        os_log(.info, "in getCurrentWordMapData")
        // When loading a map, send the loaded map and not the current extended map
        if let targetWorldMap = targetWorldMap {
//            os_log(.info, "using existing worldmap, not asking session for a new one.")
            compressMap(map: targetWorldMap, closure)
            return
        } else {
//            os_log(.info, "asking ARSession for the world map")
            sceneView.session.getCurrentWorldMap { map, error in
                // os_log(.info, "ARSession getCurrentWorldMap returned")
                if let error = error {
                   // os_log(.error, "didn't work! %s", "\(error)")
                    closure(nil, error)
                }
                guard let map = map else {
                    return
                }
//                os_log(.error, "no map either!"); return }
//                os_log(.info, "got a worldmap, compressing it")
                self.compressMap(map: map, closure)
            }
        }
    }
    
    private func compressMap(map: ARWorldMap, _ closure: @escaping (Data?, Error?) -> Void) {
        DispatchQueue.global().async {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                //os_log(.info, "data size is %d", data.count)
                let compressedData = data.compressed()
               // os_log(.info, "compressed size is %d", compressedData.count)
                closure(compressedData, nil)
            } catch {
//                os_log(.error, "archiving failed %s", "\(error)")
                closure(nil, error)
            }
        }
    }
}

extension GameViewController: GameStartViewControllerDelegate {
    
    private func createGameManager(for session: NetworkSession?) {
        gameManager = GameManager(sceneView: sceneView,
                                  session: session)
        gameManager?.start()
        setupViews()
//        startARSession()
    }
    
    func gameStartViewController(_ _: UIViewController, didPressStartSoloGameButton: UIButton) {
        hideOverlay()
        createGameManager(for: nil)
    }
    
    func gameStartViewController(_ _: UIViewController, didStart game: NetworkSession) {
        hideOverlay()
        createGameManager(for: game)
    }
    
    func gameStartViewController(_ _: UIViewController, didSelect game: NetworkSession) {
        hideOverlay()
        createGameManager(for: game)
    }
    
    
//    func gameStartViewController(_ gameStartViewController: UIViewController, didPressStartSoloGameButton: UIButton) {
//        print("gameStartViewController(_ gameStartViewController: UIViewController, didPressStartSoloGameButton: UIButton)")
//        hideOverlay()
//        setupViews()
//    }
//    
//    func gameStartViewController(_ gameStartViewController: UIViewController, didStart game: NetworkSession) {
//        print("gameStartViewController(_ gameStartViewController: UIViewController, didStart game: NetworkSession)")
//        hideOverlay()
//        setupViews()
//    }
//    
//    func gameStartViewController(_ gameStartViewController: UIViewController, didSelect game: NetworkSession) {
//        print("gameStartViewController(_ gameStartViewController: UIViewController, didSelect game: NetworkSession)")
//        hideOverlay()
//        setupViews()
//    }
    
    
}

extension GameViewController: GameManagerDelegate {
    func manager(_ manager: GameManager, addTank: AddTankNodeAction) {
        //
    }
    
    func manager(_ manager: GameManager, received boardAction: BoardSetupAction, from player: Player) {
        DispatchQueue.main.async {
            self.process(boardAction: boardAction, from: player)
        }
    }
    
    func manager(_ manager: GameManager, joiningPlayer player: Player) {
        //
    }
    
    func manager(_ manager: GameManager, leavingPlayer player: Player) {
        //
    }
    
    func manager(_ manager: GameManager, joiningHost host: Player) {
        // MARK: request worldmap when joining the host
        DispatchQueue.main.async {
            if self.sessionState == .waitingForBoard {
                manager.send(boardAction: .requestBoardLocation)
            }
            guard !UserDefaults.standard.disableInGameUI else { return }
        }
    }
    
    func manager(_ manager: GameManager, leavingHost host: Player) {
        //
    }
    
    func managerDidStartGame(_ manager: GameManager) {
        //
    }
    
    
}
