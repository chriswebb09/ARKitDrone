//
//  GameViewController.swift
//  ARKitDrone
//
//  Simplified game view controller
//

import UIKit
import RealityKit
import ARKit
import SpriteKit

extension NSNotification.Name {
    static let advanceTarget = NSNotification.Name("advanceTarget")
    static let shipDestroyed = NSNotification.Name("shipDestroyed")
}

class GameViewController: UIViewController, MissileManagerDelegate {
    
    // MARK: - Properties
    
    let stateManager = GameStateManager()
    let game = Game()
    let myself = UserDefaults.standard.myself
    
    var gameManager: GameManager? {
        didSet {
            gameManager?.delegate = self
        }
    }
    
    lazy var realityKitView: GameSceneView = {
        let arView = GameSceneView(frame: view.bounds)
        return arView
    }()
    
    var missileManager: MissileManager?
    var shipManager: ShipManager?
    var focusSquare: FocusSquare! = FocusSquare()
    var focusSquareAnchor: AnchorEntity?
    
    // UI Elements
    lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle("ARM MISSILES", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .black)
        button.frame = CGRect(x: UIScreen.main.bounds.width - 230, y: 220, width: 160, height: 40)
        button.backgroundColor = UIColor(red: 1.0, green: 0.03, blue: 0.0, alpha: 1.0)
        button.layer.borderColor = UIColor(red: 1.0, green: 0.03, blue: 0.0, alpha: 1.0).cgColor
        button.layer.borderWidth = 3
        return button
    }()
    
    lazy var scoreText: UILabel = {
        let label = UILabel()
        label.text = "Score: 0"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 22, weight: .black)
        label.textColor = UIColor(red: 0.0, green: 1.0, blue: 0.01, alpha: 1.0)
        label.backgroundColor = .black
        label.frame = CGRect(x: 40, y: 50, width: 130, height: 50)
        return label
    }()
    
    lazy var destoryedText: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor(red: 1.0, green: 0.03, blue: 0.0, alpha: 1.0)
        label.backgroundColor = .clear
        label.font = UIFont(name: "AvenirNext-Bold", size: 26)
        label.frame = CGRect(x: UIScreen.main.bounds.width / 2 - 200, y: 100, width: 400, height: 60)
        return label
    }()
    
    // Health Bar
    lazy var healthBarBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 5
        view.frame = CGRect(x: 40, y: 110, width: 200, height: 30)
        return view
    }()
    
    lazy var healthBarFill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.green
        view.layer.cornerRadius = 3
        view.frame = CGRect(x: 2, y: 2, width: 196, height: 26)
        return view
    }()
    
    lazy var healthBarLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textColor = .white
        label.text = "Health: 100/100"
        label.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
        return label
    }()
    
    // Joystick Views
    lazy var padView1: SKView = {
        let size: CGFloat = UIDevice.current.isIpad ? 220 : 200
        let offset: CGFloat = UIDevice.current.isIpad ? 220 : 180
        let frame = CGRect(x: 60, y: UIScreen.main.bounds.height - offset, width: size, height: size)
        let view = SKView(frame: frame)
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var padView2: SKView = {
        let size: CGFloat = UIDevice.current.isIpad ? 220 : 200
        let offset: CGFloat = UIDevice.current.isIpad ? 220 : 180
        let frame = CGRect(x: 600, y: UIScreen.main.bounds.height - offset, width: size, height: size)
        let view = SKView(frame: frame)
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    // AR Session Management
    private let arSessionManager = ARSessionManager()
    let gameStartViewContoller = GameStartViewController()
    var overlayView: UIView?
    
    // AR Coaching Overlay
    lazy var coachingOverlay: ARCoachingOverlayView = {
        let overlay = ARCoachingOverlayView()
        return overlay
    }()
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        
        game.stateManager = stateManager
        
        Task {
            await setupRealityKit()
        }
        
        setupNotifications()
        setupStartOverlay()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSessionManager.pauseSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupStartOverlay() {
        overlayView = gameStartViewContoller.view
        gameStartViewContoller.delegate = self
        view.addSubview(overlayView!)
        view.bringSubviewToFront(overlayView!)
    }
    
    private func setupRealityKit() async {
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
        let arConfiguration = ARSessionSettings(
            enableSceneReconstruction: false,
            planeDetection: [.horizontal],
            environmentMapName: "environment_blur.exr"
        )
        
        await arSessionManager.configure(arView: realityKitView, configuration: arConfiguration)
        realityKitView.session.delegate = self
        await arSessionManager.startSession(with: [.resetTracking, .removeExistingAnchors])
        await realityKitView.setup()
        
        await MainActor.run {
            // Setup managers
            missileManager = MissileManager(game: game, sceneView: realityKitView, gameManager: gameManager, localPlayer: myself)
            missileManager?.delegate = self
            shipManager = ShipManager(game: game, arView: realityKitView)
            missileManager?.shipManager = shipManager
            
            // Setup focus square
            focusSquareAnchor = AnchorEntity(world: SIMD3<Float>(0, 0, -1))
            focusSquareAnchor!.addChild(focusSquare)
            realityKitView.scene.addAnchor(focusSquareAnchor!)
            focusSquare.unhide()
            
            // Setup coaching overlay
            setupCoachingOverlay()
        }
    }
    
    private func setupUI() {
        UIApplication.shared.isIdleTimerDisabled = true
        
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
        
        // Setup joysticks
        setupJoysticks()
        
        // Setup button action
        armMissilesButton.addTarget(self, action: #selector(didTapUIButton), for: .touchUpInside)
        
        // Setup gestures
        setupGestures()
    }
    
    private func setupJoysticks() {
        // Left joystick
        let scene1 = JoystickScene()
        scene1.point = CGPoint(x: 0, y: 0)
        scene1.size = CGSize(width: 190, height: 190)
        scene1.joystickDelegate = self
        scene1.stickNum = 2
        scene1.scaleMode = .resizeFill
        padView1.preferredFramesPerSecond = 60
        padView1.presentScene(scene1)
        padView1.ignoresSiblingOrder = true
        
        // Right joystick
        let scene2 = JoystickScene()
        scene2.point = CGPoint(x: 0, y: 0)
        scene2.size = CGSize(width: 190, height: 190)
        scene2.joystickDelegate = self
        scene2.stickNum = 1
        scene2.scaleMode = .resizeFill
        padView2.preferredFramesPerSecond = 60
        padView2.presentScene(scene2)
        padView2.ignoresSiblingOrder = true
    }
    
    private func setupGestures() {
        // Target switching gestures
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(switchToNextTarget))
        leftSwipe.direction = .left
        realityKitView.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(switchToPreviousTarget))
        rightSwipe.direction = .right
        realityKitView.addGestureRecognizer(rightSwipe)
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(enableAutoTargeting))
        doubleTap.numberOfTapsRequired = 2
        realityKitView.addGestureRecognizer(doubleTap)
    }
    
    private func setupNotifications() {
        let notifications: [(Notification.Name, Selector)] = [
            (.missileCanHit, #selector(missileCanHit)),
            (.advanceTarget, #selector(advanceToNextTarget)),
            (.updateScore, #selector(updateScoreUI)),
            (.shipDestroyed, #selector(updateGameStateText)),
            (.helicopterHealthChanged, #selector(handleHealthChanged)),
            (.helicopterDestroyed, #selector(handleHelicopterDestroyed)),
            (NSNotification.Name("HelicopterTakeDamage"), #selector(handleHelicopterTakeDamage))
        ]
        
        for (name, selector) in notifications {
            NotificationCenter.default.addObserver(self, selector: selector, name: name, object: nil)
        }
    }
    
    // MARK: - Game Actions
    
    
    @objc private func didTapUIButton() {
        print("🎯 ARM MISSILE button tapped")
        print("🎯 helicopterPlaced: \(stateManager.helicopterPlaced)")
        print("🎯 helicopterAlive: \(stateManager.helicopterAlive)")
        print("🎯 missilesArmed before: \(stateManager.missilesArmed)")
        
        stateManager.toggleMissileArmed()
        
        print("🎯 missilesArmed after: \(stateManager.missilesArmed)")
        
        let currentTitle = armMissilesButton.title(for: .normal)
        let newTitle = currentTitle == "ARM MISSILES" ? "DISARM MISSILES" : "ARM MISSILES"
        armMissilesButton.setTitle(newTitle, for: .normal)
        
        if let localHelicopter = gameManager?.getHelicopter(for: myself) {
            localHelicopter.toggleMissileArmed()
            print("🎯 Helicopter missile armed: \(localHelicopter.missilesArmed())")
        } else {
            print("🎯 No local helicopter found")
        }
    }
    
    @objc private func switchToNextTarget() {
        shipManager?.switchToNextTarget()
    }
    
    @objc private func switchToPreviousTarget() {
        shipManager?.switchToPreviousTarget()
    }
    
    @objc private func enableAutoTargeting() {
        shipManager?.isAutoTargeting = true
        shipManager?.updateAutoTarget()
    }
    
    @objc func missileCanHit() {
        game.valueReached = true
    }
    
    @objc func advanceToNextTarget() {
        DispatchQueue.main.async {
            self.shipManager?.switchToNextTarget()
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !game.placed else { return }
        
        let tapLocation = touch.location(in: realityKitView)
        
        guard let raycastQuery = realityKitView.makeRaycastQuery(
            from: tapLocation,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ) else { return }
        
        let results = realityKitView.session.raycast(raycastQuery)
        guard let firstResult = results.first else { return }
        
        // Verify horizontal plane
        if let planeAnchor = firstResult.anchor as? ARPlaneAnchor {
            guard planeAnchor.alignment == .horizontal else { return }
        }
        
        // Create helicopter
        let angles = SIMD3<Float>(0, 0, 0)
        let worldTransform = firstResult.worldTransform
        let addNode = AddNodeAction(simdWorldTransform: worldTransform, eulerAngles: angles)
        
        focusSquare.hide()
        focusSquare.isEnabled = false
        game.placed = true
        
        Task { @MainActor in
            await gameManager?.createHelicopter(addNodeAction: addNode, owner: myself)
            
            stateManager.helicopterPlaced = true
            stateManager.transitionTo(SessionState.gameInProgress)
            print("🚁 Helicopter placed - helicopterPlaced: \(stateManager.helicopterPlaced), helicopterAlive: \(stateManager.helicopterAlive), canArm: \(stateManager.helicopterPlaced && stateManager.helicopterAlive)")
            
            realityKitView.placeTankOnSurface(at: tapLocation)
            
            if let localHelicopter = gameManager?.getHelicopter(for: myself),
               let helicopterEntity = localHelicopter.helicopterEntity?.helicopter {
                shipManager?.helicopterEntity = helicopterEntity
                await shipManager?.setupShips()
                startGameLoops()
            }
            
            if let gameManager = gameManager, gameManager.isNetworked {
                gameManager.send(addNode: addNode)
            }
        }
    }
    
    private func startGameLoops() {
        // Ship movement loop
        Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                self.shipManager?.moveShips(placed: self.game.placed)
                self.shipManager?.updateAutoTarget()
            }
        }
        
        // Missile cleanup loop
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                self.missileManager?.cleanupExpiredMissiles()
            }
        }
    }
    
    // MARK: - UI Updates
    
    @objc func updateScoreUI() {
        Task { @MainActor in
            stateManager.score = game.score
            scoreText.text = "Score: \(game.score)"
            game.scoreUpdated = false
        }
    }
    
    func updateHealthBar(currentHealth: Float, maxHealth: Float) {
        let percentage = currentHealth / maxHealth
        let newWidth = CGFloat(196 * percentage)
        
        UIView.animate(withDuration: 0.3) {
            self.healthBarFill.frame.size.width = newWidth
            
            if percentage > 0.6 {
                self.healthBarFill.backgroundColor = .green
            } else if percentage > 0.3 {
                self.healthBarFill.backgroundColor = .orange
            } else {
                self.healthBarFill.backgroundColor = .red
            }
        }
        
        healthBarLabel.text = "Health: \(Int(currentHealth))/\(Int(maxHealth))"
    }
    
    @objc func handleHealthChanged(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let currentHealth = userInfo["currentHealth"] as? Float,
              let maxHealth = userInfo["maxHealth"] as? Float else { return }
        
        stateManager.updateHelicopterHealth(currentHealth)
        updateHealthBar(currentHealth: currentHealth, maxHealth: maxHealth)
    }
    
    @objc func handleHelicopterDestroyed(_ notification: Notification) {
        guard stateManager.gameInProgress || stateManager.helicopterPlaced else { return }
        
        DispatchQueue.main.async {
            self.destoryedText.text = "HELICOPTER DESTROYED"
            self.destoryedText.textColor = UIColor.red
            
            self.armMissilesButton.isEnabled = false
            self.padView1.isUserInteractionEnabled = false
            self.padView2.isUserInteractionEnabled = false
            
            self.updateHealthBar(currentHealth: 0, maxHealth: 100)
        }
    }
    
    @objc func handleHelicopterTakeDamage(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let damage = userInfo["damage"] as? Float,
              let source = userInfo["source"] as? String else { return }
        
        stateManager.damageHelicopter(damage, from: source)
        
        if let localHelicopter = gameManager?.getHelicopter(for: myself) {
            localHelicopter.takeDamage(damage, from: source)
        }
    }
    
    func hideOverlay() {
        UIView.transition(with: view, duration: 1.0, options: [.transitionCrossDissolve], animations: {
            self.overlayView!.isHidden = true
        }) { _ in
            self.overlayView!.isUserInteractionEnabled = false
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    // MARK: - MissileManagerDelegate
    
    func missileManager(_ manager: MissileManager, didUpdateScore score: Int) {
        stateManager.destroyShip(worth: 100)
        updateScoreUI()
    }
    
    // MARK: - Orientation
    
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