//
//  ViewController.swift
//  ARKitDrone
//
//  Created by Christopher Webb-Orenstein on 10/7/17.
//  Copyright © 2017 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import RealityKit
@preconcurrency import ARKit
import SpriteKit
import os.log

extension NSNotification.Name {
    static let advanceTarget = NSNotification.Name("advanceTarget")
}

class GameViewController: UIViewController, MissileManagerDelegate {
    
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
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let joystickSize = CGSize(width: 190, height: 190)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = "Models.scnassets/sharedImages/environment_blur.exr"
        static let buttonTitle = "Arm Missiles".uppercased()
        static let disarmTitle = "Disarm Missiles".uppercased()
    }
    
    // MARK: - Private Properties
    
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
    
    
    lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle(LocalConstants.buttonTitle, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.black)
        button.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width - 200, y: 100), size: CGSize(width: 180, height: 60))
        button.layer.borderColor = UIColor(red: 1.00, green: 0.03, blue: 0.00, alpha: 1.00).cgColor
        //UIColor(red: 0.95, green: 0.15, blue: 0.07, alpha: 1.00).cgColor
        button.backgroundColor = UIColor(
            red: 1.00,
            green: 0.03,
            blue: 0.00,
            alpha: 1.00
        )
        button.layer.borderWidth = 3
        button.isEnabled = true
        return button
    }()
    
    var focusSquareAnchor: AnchorEntity? = nil
    
    lazy var destoryedText: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor(
            red: 1.00,
            green: 0.03,
            blue: 0.00,
            alpha: 1.00
        )
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
        label.frame = CGRect(
            origin: CGPoint(
                x: 40 ,
                y:  UIScreen.main.bounds.origin.y + 50
            ),
            size: CGSize(width: 130, height: 50)
        )
        return label
    }()
    
    let coachingOverlay = ARCoachingOverlayView()
    
    var sessionState: SessionState = .setup
    
    let game = Game()
    
    var focusSquare: FocusSquare! = FocusSquare()
    
    
    // used when state is localizingToWorldMap or localizingToSavedMap
    var targetWorldMap: ARWorldMap?
    let gameStartViewContoller = GameStartViewController()
    var overlayView: UIView?
    
    
    // MARK: - RealityKit Properties
    lazy var realityKitView: GameSceneView = {
        let arView = GameSceneView(frame: view.bounds)
        return arView
    }()
    
    var missileManager: MissileManager?
    var shipManager: ShipManager?
    
    // MARK: - Common Properties
    var addsMesh = false
    var isLoaded = false
    let myself = UserDefaults.standard.myself
    var session: ARSession {
        return realityKitView.session
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        
        // Start async setup immediately
        Task {
            await setupRealityKitAsync()
        }
        
        // Setup notifications
        NotificationCenter.default.addObserver(self, selector: #selector(missileCanHit), name: .missileCanHit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(advanceToNextTarget), name: .advanceTarget, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateScoreUI), name: .updateScore, object: nil)
        
        overlayView = gameStartViewContoller.view
        gameStartViewContoller.delegate = self
        view.addSubview(overlayView!)
        view.bringSubviewToFront(overlayView!)
    }
    
    private func setupRealityKitAsync() async {
        guard realityKitView.superview == nil else { return }
        
        await MainActor.run {
            view.insertSubview(realityKitView, at: 0)
            
            realityKitView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                realityKitView.topAnchor.constraint(equalTo: view.topAnchor),
                realityKitView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                realityKitView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                realityKitView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        if addsMesh {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                config.sceneReconstruction = .meshWithClassification
                config.frameSemantics = .sceneDepth
            }
        }
        realityKitView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        realityKitView.session.delegate = self
        
        // Setup RealityKit view async
        await realityKitView.setup()
        
        await MainActor.run {
            // Setup managers
            missileManager = MissileManager(game: game, sceneView: realityKitView)
            missileManager?.delegate = self
            shipManager = ShipManager(game: game, arView: realityKitView)
            
            // Add UI elements
            realityKitView.addSubview(padView1)
            realityKitView.addSubview(padView2)
            realityKitView.addSubview(destoryedText)
            realityKitView.addSubview(armMissilesButton)
            realityKitView.addSubview(scoreText)
            
            focusSquareAnchor = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
            focusSquareAnchor!.addChild(focusSquare)
            realityKitView.scene.addAnchor(focusSquareAnchor!)
            focusSquare.unhide()
        }
    }
    
    private func setupRealityKit() {
        guard realityKitView.superview == nil else { return }
        view.insertSubview(realityKitView, at: 0)
        
        realityKitView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            realityKitView.topAnchor.constraint(equalTo: view.topAnchor),
            realityKitView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            realityKitView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            realityKitView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // ✅ Run AR session here - detect both horizontal and vertical planes
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        if addsMesh {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                config.sceneReconstruction = .meshWithClassification
                config.frameSemantics = .sceneDepth
            }
        }
        realityKitView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        realityKitView.session.delegate = self
        
        // Setup the RealityKit view
        Task {
            await realityKitView.setup()
        }
        
        // Setup RealityKit managers
        missileManager = MissileManager(
            game: game,
            sceneView: realityKitView
        )
        missileManager?.delegate = self
        shipManager = ShipManager(
            game: game,
            arView: realityKitView
        )
        
        realityKitView.addSubview(padView1)
        realityKitView.addSubview(padView2)
        realityKitView.addSubview(destoryedText)
        realityKitView.addSubview(armMissilesButton)
        realityKitView.addSubview(scoreText)
        
        // Setup coaching overlay
        //        setupCoachingOverlay()
        
    }
    
    // MARK: - Game Setup
    
    func setupGameSession() {
        setupRealityKit()
        
        // Reset game state for new session
        game.scoreUpdated = false
        game.valueReached = false
        
        // Sync ship managers
        if let shipManager = shipManager {
            realityKitView.ships = shipManager.ships
        }
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
        realityKitView.session.pause()
    }
    
    func setupViews() {
        UIApplication.shared.isIdleTimerDisabled = true
        //        resetTrackingForRealityKit()
        
        // Add joystick pads
        realityKitView.addSubview(padView1)
        realityKitView.addSubview(padView2)
        setupPadScene(
            padView1: padView1,
            padView2: padView2
        )
        
        // Add UI elements
        realityKitView.addSubview(destoryedText)
        realityKitView.addSubview(armMissilesButton)
        realityKitView.addSubview(scoreText)
        
        
        armMissilesButton.addTarget(
            self,
            action: #selector(didTapUIButton),
            for: .touchUpInside
        )
        self.isLoaded = true
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            DeviceOrientation.shared.set(orientation: .landscapeRight)
        } else {
            DeviceOrientation.shared.set(orientation: .portrait)
        }
        
        focusSquareAnchor = AnchorEntity(world: SIMD3<Float>(0, 0, -1))  // <-- Assign to class property!
        focusSquareAnchor!.addChild(focusSquare)
        realityKitView.scene.addAnchor(focusSquareAnchor!)
        focusSquare.unhide()
    }
    
    func setupPlayerNode() {
        // Player node setup not needed in RealityKit mode
        // RealityKit uses camera tracking directly
    }
    
    
    // MARK: - Private Methods
    
    
    @objc func startGame() {
        let gameSession = NetworkSession(
            myself: myself,
            asServer: true,
            host: myself
        )
        gameManager = GameManager(
            arView: realityKitView,
            session: gameSession
        )
        gameManager?.start()
    }
    
    func updateMinimap() {
        // TODO: Implement minimap updates when needed
    }
    
    
    func resetTrackingForRealityKit() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        
        if addsMesh {
            let reconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(reconstruction) {
                configuration.sceneReconstruction = reconstruction
                configuration.frameSemantics = .sceneDepth
            }
        }
        
        // Run session on the RealityKit ARView
        realityKitView.automaticallyConfigureSession = false // ✅ You configure manually
        realityKitView.environment.sceneUnderstanding.options = []
        
        realityKitView.session.run(
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
        padView1.preferredFramesPerSecond = 60
        padView1.presentScene(scene)
        padView1.ignoresSiblingOrder = true
        let scene2 = JoystickScene()
        scene2.point = LocalConstants.joystickPoint
        scene2.size = LocalConstants.joystickSize
        scene2.joystickDelegate = self
        scene2.stickNum = 1
        scene2.scaleMode = .resizeFill
        padView2.preferredFramesPerSecond = 60
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
        let currentTitle = armMissilesButton.title(for: .normal)
        let newTitle = currentTitle == LocalConstants.buttonTitle ? LocalConstants.disarmTitle : LocalConstants.buttonTitle
        armMissilesButton.setTitle(newTitle, for: .normal)
        
        // Toggle helicopter missiles state
        realityKitView.helicopter?.toggleArmMissile()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        // Don't place helicopter if it's already placed
        
        let tapLocation: CGPoint = touch.location(in: realityKitView)
        
        if game.placed {
            
            return
        }
        
        
        // Perform raycast from tap location - only allow horizontal planes
        let raycastQuery = realityKitView.makeRaycastQuery(
            from: tapLocation,
            allowing: .estimatedPlane,
            alignment: .horizontal
        )
        
        guard let query = raycastQuery else {
            return
        }
        let results = realityKitView.session.raycast(query)
        guard let firstResult = results.first else {
            return
        }
        
        // Verify this is a horizontal plane if it has an anchor
        if let planeAnchor = firstResult.anchor as? ARPlaneAnchor {
            guard planeAnchor.alignment == .horizontal else {
                return
            }
        }
        
        let tappedPosition = SIMD3<Float>(
            firstResult.worldTransform.columns.3.x,
            firstResult.worldTransform.columns.3.y,
            firstResult.worldTransform.columns.3.z
        )
        
        // Position helicopter at tapped location
        Task {
            guard let helicopter = await realityKitView.positionHelicopter(at: tappedPosition) else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                realityKitView.helicopter = helicopter
                
                // Reset target transform for smooth movement from new position
                helicopter.resetTargetTransform()
                
                // Use default rotation angles (if you want different rotation, update here)
                let angles = SIMD3<Float>(0, 0, 0)
                
                // Make sure firstResult.worldTransform is available
                let worldTransform = firstResult.worldTransform
                
                let addNode = AddNodeAction(
                    simdWorldTransform: worldTransform,
                    eulerAngles: angles
                )
                
                os_log(.info, "Sending add node action for multiplayer")
                
                gameManager?.send(addNode: addNode)
                
                // Hide focus square and mark game as placed
                focusSquare.hide()
                game.placed = true
                
                // Ensure focus square stays hidden by disabling it completely
                focusSquare.isEnabled = false
                realityKitView.placeTankOnSurface(at: tapLocation)
                
                // Set helicopter entity for managers
                let helicopterEntity = realityKitView.helicopter.helicopter
                shipManager?.helicopterEntity = helicopterEntity
                
                // Setup ships immediately on main thread for responsiveness
                Task {
                    await shipManager?.setupShips()
                }
            }
        }
        
    }
    
    private func startShipMovementLoop() {
        Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] timer in // 30fps for smooth movement
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                self.shipManager?.moveShips(placed: self.game.placed)
            }
        }
    }
    
    func sendWorldTo(peer: Player) {
        guard let gameManager = gameManager, gameManager.isServer else {
            os_log(.error, "i'm not the server")
            return
        }
        
        switch UserDefaults.standard.boardLocatingMode {
        case .worldMap:
            os_log(.info, "generating worldmap for %s", "\(peer)")
            getCurrentWorldMapData {
                data,
                error in
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
                    gameManager.send(
                        boardAction: .boardLocation(location),
                        to: peer
                    )
                }
            }
        case .manual:
            os_log(.info, "manual board location")
            gameManager.send(
                boardAction: .boardLocation(.manual),
                to: peer
            )
        }
    }
    
    
    
    func loadWorldMap(from archivedData: Data) {
        do {
            os_log(.info, "Loading world map")
            
            // Decompress the data if compressed
            let uncompressedData = try archivedData.decompressed()
            
            // Unarchive the ARWorldMap from the data
            guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: ARWorldMap.self,
                from: uncompressedData
            ) else {
                os_log(.error, "The WorldMap received couldn't be read")
                DispatchQueue.main.async {
                    self.sessionState = .setup
                }
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.targetWorldMap = worldMap
                // Setup ARWorldTrackingConfiguration with loaded world map
                let configuration = ARWorldTrackingConfiguration()
                configuration.initialWorldMap = worldMap
                configuration.planeDetection = [.horizontal]
                if self.addsMesh {
                    if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                        configuration.sceneReconstruction = .meshWithClassification
                        configuration.frameSemantics = .sceneDepth
                    }
                }
                // Since you manually configure the session
                self.realityKitView.automaticallyConfigureSession = false
                // Run the AR session with options to reset tracking and anchors
                self.realityKitView.session.run(
                    configuration,
                    options: [
                        .resetTracking,
                        .removeExistingAnchors,
                        .resetSceneReconstruction,
                        .stopTrackedRaycasts
                    ]
                )
                os_log(.info, "RealityKit session started with world map")
                Task {
                    do {
                        let environmentResource = try await EnvironmentResource(named: LocalConstants.environmentalMap)
                        self.realityKitView.environment.lighting.resource = environmentResource
                    } catch {
                        os_log(.error, "Failed to load environment resource: %{public}@", error.localizedDescription)
                    }
                }
                
                if let focusSquareAnchor = self.focusSquareAnchor, !self.realityKitView.scene.anchors.contains(where: { $0 == focusSquareAnchor }) {
                    self.realityKitView.scene.addAnchor(focusSquareAnchor)
                }
                // Update focus square state if needed
                self.updateFocusSquare(isObjectVisible: false)
            }
        } catch {
            os_log(.error, "The WorldMap received couldn't be decompressed")
            DispatchQueue.main.async {
                self.sessionState = .setup
            }
        }
    }
    
    
    func getCurrentWorldMapData(_ closure: @Sendable @escaping (Data?, Error?) -> Void) {
        os_log(.info, "in getCurrentWordMapData")
        // When loading a map, send the loaded map and not the current extended map
        if let targetWorldMap = targetWorldMap {
            os_log(.info, "using existing worldmap, not asking session for a new one.")
            compressMap(map: targetWorldMap, closure)
            return
        } else {
            os_log(.info, "asking ARSession for the world map")
            realityKitView.session.getCurrentWorldMap { map, error in
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
    
    private func compressMap(map: ARWorldMap, _ closure: @Sendable @escaping (Data?, Error?) -> Void) {
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
    
    @objc func advanceToNextTarget() {
        DispatchQueue.main.async {
            self.shipManager?.addTargetToShip()
        }
    }
    
    @objc func updateScoreUI() {
        print("🎯 Updating score UI")
        DispatchQueue.main.async {
            self.scoreText.text = self.game.scoreTextString
        }
    }
    
    // MARK: - MissileManagerDelegate
    
    func missileManager(_ manager: MissileManager, didUpdateScore score: Int) {
        print("🎯 Score updated to: \(score)")
        updateScoreUI()
    }
    
    // MARK: - Orientation Control
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
}
