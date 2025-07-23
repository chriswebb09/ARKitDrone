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
    
    // MARK: - State Management
    
    @MainActor let stateManager = GameStateManager()
    private var stateObservationTask: Task<Void, Never>?
    
    var gameManager: GameManager? {
        didSet {
            guard let manager = gameManager else {
                stateManager.transitionTo(SessionState.setup)
                return
            }
            if manager.isNetworked && !manager.isServer {
                stateManager.setupNetworkedGame(asServer: false, connectedPlayers: [])
            } else {
                stateManager.setupNetworkedGame(asServer: true, connectedPlayers: [])
            }
            manager.delegate = self
        }
    }
    
    // MARK: - LocalConstants
    
    private struct LocalConstants {
        static let joystickSize = CGSize(width: 190, height: 190)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = "environment_blur.exr"
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
        let frame = CGRect(
            x:60,
            y: UIScreen.main.bounds.height - offset,
            width: sizeOffset,
            height: sizeOffset
        )
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
        let frame = CGRect(
            x:600,
            y: UIScreen.main.bounds.height - offset,
            width: sizeOffset,
            height: sizeOffset
        )
        let view = SKView(frame: frame)
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    
    lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle(
            LocalConstants.buttonTitle,
            for: .normal
        )
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(
            ofSize: 14,
            weight: UIFont.Weight.black
        )
        button.frame = CGRect(
            origin: CGPoint(
                x: UIScreen.main.bounds.width - 230,
                y: 220
            ),
            size: CGSize(width: 160, height: 40)
        )
        button.layer.borderColor = UIColor(
            red: 1.00,
            green: 0.03,
            blue: 0.00,
            alpha: 1.00
        ).cgColor
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
            size: 26
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
        label.font = UIFont.systemFont(
            ofSize: 22,
            weight: UIFont.Weight.black
        )
        label.textColor = UIColor(
            red: 0.00,
            green: 1.00,
            blue: 0.01,
            alpha: 1.00
        )
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
    
    // MARK: - Health Bar UI
    
    lazy var healthBarBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 5
        view.frame = CGRect(
            origin: CGPoint(x: 40, y: UIScreen.main.bounds.origin.y + 110),
            size: CGSize(width: 200, height: 30)
        )
        return view
    }()
    
    lazy var healthBarFill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green
        view.layer.cornerRadius = 3
        view.frame = CGRect(
            origin: CGPoint(x: 2, y: 2),
            size: CGSize(width: 196, height: 26)
        )
        return view
    }()
    
    lazy var healthBarLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.text = "Health: 100/100"
        label.frame = CGRect(
            origin: CGPoint(x: 0, y: 0),
            size: CGSize(width: 200, height: 30)
        )
        return label
    }()
    
    let coachingOverlay = ARCoachingOverlayView()
    
    let game = Game()
    
    // Connect game to state manager after initialization
    private func connectGameToStateManager() {
        game.stateManager = stateManager
    }
    
    var focusSquare: FocusSquare! = FocusSquare()
    
    // used when state is localizingToWorldMap or localizingToSavedMap
    var targetWorldMap: ARWorldMap?
    let gameStartViewContoller = GameStartViewController()
    var overlayView: UIView?
    
    
    // MARK: - Properties
    lazy var realityKitView: GameSceneView = {
        let arView = GameSceneView(frame: view.bounds)
        return arView
    }()
    
    var missileManager: MissileManager?
    var shipManager: ShipManager?
    var targetingManager: TargetingManager?
    
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
        
        // Setup state management
        setupStateManagement()
        connectGameToStateManager()
        
        // Start async setup immediately
        Task {
            await setupRealityKitAsync()
        }
        
        // Setup notifications
        setupNotifications()
        
        overlayView = gameStartViewContoller.view
        gameStartViewContoller.delegate = self
        view.addSubview(overlayView!)
        view.bringSubviewToFront(overlayView!)
    }
    
    deinit {
        stateObservationTask?.cancel()
    }
    
    // MARK: - State Management Setup
    
    private func setupStateManagement() {
        // Use modern Swift concurrency for state observation
        stateObservationTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            var lastSessionState: SessionState?
            var lastScore: Int?
            
            while !Task.isCancelled {
                // Check for session state changes
                let currentSessionState = self.stateManager.sessionState
                if lastSessionState != currentSessionState {
                    lastSessionState = currentSessionState
                    self.handleSessionStateChange(currentSessionState)
                }
                
                // Check for score changes (throttled)
                let currentScore = self.stateManager.score
                if lastScore != currentScore {
                    lastScore = currentScore
                    self.scoreText.text = "Score: \(currentScore)"
                }
                
                // Sleep for 250ms to reduce polling overhead
                do {
                    try await Task.sleep(nanoseconds: 250_000_000) // 250ms
                } catch {
                    // Task was cancelled, exit gracefully
                    break
                }
            }
        }
    }
    
    @MainActor private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(missileCanHit),
            name: .missileCanHit,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(advanceToNextTarget),
            name: .advanceTarget,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateGameStateText),
            name: .updateScore,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHealthChanged),
            name: .helicopterHealthChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHelicopterDestroyed),
            name: .helicopterDestroyed,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHelicopterTakeDamage),
            name: NSNotification.Name("HelicopterTakeDamage"),
            object: nil
        )
    }
    
    private func handleSessionStateChange(_ newState: SessionState) {
        os_log(.info, "🎮 Handling session state change: %@", newState.description)
        
        switch newState {
        case SessionState.setup:
            game.placed = false
            game.scoreUpdated = false
            game.valueReached = false
            // Clear any game over messages
            destoryedText.text = ""
            
        case SessionState.lookingForSurface:
            // Clear game over messages when starting to look for surface
            destoryedText.text = ""
            
        case SessionState.gameInProgress:
            // Clear any lingering messages when game starts
            destoryedText.text = ""
            
        default:
            break
        }
    }
    
    private func updateControlsState(enabled: Bool) {
        armMissilesButton.isEnabled = enabled
        padView1.isUserInteractionEnabled = enabled
        padView2.isUserInteractionEnabled = enabled
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
        
        // Setup view async
        await realityKitView.setup()
        
        await MainActor.run {
            // Setup managers
            missileManager = MissileManager(game: game, sceneView: realityKitView, gameManager: gameManager, localPlayer: myself)
            missileManager?.delegate = self
            shipManager = ShipManager(game: game, arView: realityKitView)
            targetingManager = TargetingManager()
            
            // Connect targeting manager to missile manager
            missileManager?.targetingManager = targetingManager
            
            // Add UI elements
            realityKitView.addSubview(padView1)
            realityKitView.addSubview(padView2)
            realityKitView.addSubview(destoryedText)
            realityKitView.addSubview(armMissilesButton)
            realityKitView.addSubview(scoreText)
            
            // Add health bar
            realityKitView.addSubview(healthBarBackground)
            healthBarBackground.addSubview(healthBarFill)
            healthBarBackground.addSubview(healthBarLabel)
            
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
        
        // Setup the view
        Task {
            await realityKitView.setup()
        }
        
        // Setup managers
        missileManager = MissileManager(
            game: game,
            sceneView: realityKitView,
            gameManager: gameManager,
            localPlayer: myself
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
        
        // Reset game state for new session through state manager (async)
        Task { @MainActor in
            await stateManager.resetGameState()
        }
        
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
        
        // Add target switching gestures
        setupTargetSwitchingGestures()
    }
    
    func setupPlayerNode() {
        // Player node setup not needed in RealityKit mode
        // RealityKit uses camera tracking directly
    }
    
    // MARK: - Target Switching Gestures
    
    private func setupTargetSwitchingGestures() {
        // Left swipe for next target
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(switchToNextTarget))
        leftSwipe.direction = .left
        realityKitView.addGestureRecognizer(leftSwipe)
        
        // Right swipe for previous target
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(switchToPreviousTarget))
        rightSwipe.direction = .right
        realityKitView.addGestureRecognizer(rightSwipe)
        
        // Double tap to enable auto-targeting
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(enableAutoTargeting))
        doubleTap.numberOfTapsRequired = 2
        realityKitView.addGestureRecognizer(doubleTap)
    }
    
    @objc private func switchToNextTarget() {
        targetingManager?.switchToNextTarget()
        print("🎯 Switched to next target")
    }
    
    @objc private func switchToPreviousTarget() {
        targetingManager?.switchToPreviousTarget()
        print("🎯 Switched to previous target")
    }
    
    @objc private func enableAutoTargeting() {
        targetingManager?.enableAutoTargeting()
        print("🎯 Auto-targeting enabled")
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
        
        // Setup networked game state
        stateManager.setupNetworkedGame(asServer: true, connectedPlayers: [myself])
        
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
        
        // Run session on the ARView
        realityKitView.automaticallyConfigureSession = false
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
        // Update state through state manager
        stateManager.toggleMissileArmed()
        
        // Update UI
        let currentTitle = armMissilesButton.title(for: .normal)
        let newTitle = currentTitle == LocalConstants.buttonTitle ? LocalConstants.disarmTitle : LocalConstants.buttonTitle
        armMissilesButton.setTitle(newTitle, for: .normal)
        
        // Toggle helicopter missiles state through HelicopterObject system
        if let localHelicopter = gameManager?.getHelicopter(for: myself) {
            localHelicopter.toggleMissileArmed()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let tapLocation: CGPoint = touch.location(in: realityKitView)
        
        // Simple, direct check to avoid state manager overhead
        guard !game.placed else {
            return
        }
        
        print("👆 Tap detected at \(tapLocation) - processing placement")
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
//        let tappedPosition = SIMD3<Float>(
//            firstResult.worldTransform.columns.3.x,
//            firstResult.worldTransform.columns.3.y,
//            firstResult.worldTransform.columns.3.z
//        )
        // Create helicopter through HelicopterObject system (unified single/multiplayer)
        let angles = SIMD3<Float>(0, 0, 0)
        let worldTransform = firstResult.worldTransform
        let addNode = AddNodeAction(
            simdWorldTransform: worldTransform,
            eulerAngles: angles
        )
        
        os_log(.info, "Creating local player helicopter through HelicopterObject system")
        
        // Create local player helicopter using the new multiplayer architecture
        Task { @MainActor in
            await gameManager?.createHelicopter(addNodeAction: addNode, owner: myself)
            
            // Hide focus square and update state efficiently
            focusSquare.hide()
            focusSquare.isEnabled = false
            
            // Update game state immediately for responsive feedback
            game.placed = true
            
            print("🚁 Helicopter placed successfully")
            
            // Update state manager in background without blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                DispatchQueue.main.async {
                    self.stateManager.helicopterPlaced = true
                    // Delayed state transition to allow helicopter setup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.stateManager.transitionTo(SessionState.gameInProgress)
                    }
                }
            }
            
            // Setup tank positioning (legacy compatibility)
            realityKitView.placeTankOnSurface(at: tapLocation)
            
            // Setup ships with local helicopter
            if let localHelicopter = gameManager?.getHelicopter(for: myself),
               let helicopterEntity = localHelicopter.helicopterEntity?.helicopter {
                shipManager?.helicopterEntity = helicopterEntity
                await shipManager?.setupShips()
                
                // Setup targeting manager with helicopter and ships
                if let ships = shipManager?.ships {
                    targetingManager?.setup(helicopterEntity: helicopterEntity, ships: ships)
                }
                
                // Start ship movement and targeting updates
                startShipMovementLoop()
                
                // Start periodic missile cleanup
                startMissileCleanupTimer()
            }
            
            // Only send to network if we have a network session (multiplayer mode)
            if let gameManager = gameManager, gameManager.isNetworked {
                gameManager.send(addNode: addNode)
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
                
                // Update targeting system
                if let ships = self.shipManager?.ships {
                    self.targetingManager?.updateShips(ships)
                    self.targetingManager?.updateTargetIndicators()
                }
            }
        }
    }
    
    private func startMissileCleanupTimer() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in // Every 30 seconds
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                self.missileManager?.cleanupExpiredMissiles()
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
                    self.stateManager.transitionTo(SessionState.setup)
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
                self.stateManager.transitionTo(SessionState.setup)
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
        // Use async Task for better performance
        Task { @MainActor in
            print("📊 updateScoreUI called - game.score: \(self.game.score), scoreUpdated: \(self.game.scoreUpdated)")
            
            // Always update the state manager score to ensure consistency
            self.stateManager.score = self.game.score
            
            // Update UI text
            let newScoreText = self.stateManager.scoreText
            print("📊 Updating score UI text to: \(newScoreText)")
            self.scoreText.text = newScoreText
            
            // Reset the scoreUpdated flag
            self.game.scoreUpdated = false
        }
    }
    
    // MARK: - Health UI Updates
    
    func updateHealthBar(currentHealth: Float, maxHealth: Float) {
        DispatchQueue.main.async {
            let percentage = currentHealth / maxHealth
            let newWidth = CGFloat(196 * percentage) // Max width is 196
            
            // Update health bar fill width
            UIView.animate(withDuration: 0.3) {
                self.healthBarFill.frame.size.width = newWidth
            }
            
            // Update health bar color based on health percentage
            let healthColor: UIColor
            if percentage > 0.6 {
                healthColor = .green
            } else if percentage > 0.3 {
                healthColor = .orange
            } else {
                healthColor = .red
            }
            
            UIView.animate(withDuration: 0.3) {
                self.healthBarFill.backgroundColor = healthColor
            }
            // Update health text
            self.healthBarLabel.text = "Health: \(Int(currentHealth))/\(Int(maxHealth))"
        }
    }
    
    @objc func handleHealthChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let currentHealth = userInfo["currentHealth"] as? Float,
              let maxHealth = userInfo["maxHealth"] as? Float else {
            print("❌ Invalid health notification data")
            return
        }
        
        print("🏥 Health notification received: \(currentHealth)/\(maxHealth)")
        
        // Update health through state manager (throttled)
        stateManager.updateHelicopterHealth(currentHealth)
        
        // Update UI directly to avoid binding overhead
        updateHealthBar(currentHealth: currentHealth, maxHealth: maxHealth)
    }
    
    @objc func handleHelicopterDestroyed(_ notification: Notification) {
        print("💀 Helicopter destroyed notification received")
        
        // Only show game over if the game has actually started
        guard stateManager.gameInProgress || stateManager.helicopterPlaced else {
            print("⚠️ Ignoring helicopter destroyed - game not started yet")
            return
        }
        
        DispatchQueue.main.async {
            // Show game over screen
            self.destoryedText.text = "HELICOPTER DESTROYED"
            self.destoryedText.textColor = UIColor.red
            
            // Disable controls
            self.armMissilesButton.isEnabled = false
            self.padView1.isUserInteractionEnabled = false
            self.padView2.isUserInteractionEnabled = false
            
            // Set health bar to zero
            self.updateHealthBar(currentHealth: 0, maxHealth: 100)
            
            // Could add restart button or return to menu logic here
        }
    }
    
    @objc func handleHelicopterTakeDamage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let damage = userInfo["damage"] as? Float,
              let source = userInfo["source"] as? String else {
            print("❌ Invalid helicopter damage notification data")
            return
        }
        
        print("💥 Helicopter damage notification: \(damage) from \(source)")
        
        // Apply damage through state manager
        stateManager.damageHelicopter(damage, from: source)
        
        // Also apply to helicopter object for visual effects
        if let localHelicopter = gameManager?.getHelicopter(for: myself) {
            print("✅ Found local helicopter in GameViewController - applying damage")
            localHelicopter.takeDamage(damage, from: source)
        } else {
            print("❌ No local helicopter found in GameViewController for damage")
            print("🔍 GameManager exists: \(gameManager != nil)")
            print("🔍 Local player: \(myself.username)")
        }
    }
    
    // MARK: - MissileManagerDelegate
    
    func missileManager(_ manager: MissileManager, didUpdateScore score: Int) {
        // Update score through state manager
        stateManager.destroyShip(worth: 100) // Standard ship destruction points
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
