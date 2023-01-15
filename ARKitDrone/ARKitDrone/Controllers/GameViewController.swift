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
    
    struct LocalConstants {
        static let joystickSize = CGSize(width: 160, height: 150)
        static let joystickPoint = CGPoint(x: 0, y: 0)
        static let environmentalMap = "Models.scnassets/sharedImages/environment_blur.exr"
    }
    
    var placed: Bool = false
    
    lazy var padView1: SKView = {
        let view = SKView(frame: CGRect(x:40, y: 20, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var padView2: SKView = {
        let view = SKView(frame: CGRect(x:660, y: UIScreen.main.bounds.height - 140, width:140, height: 140))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var armMissilesButton: UIButton = {
        let button = UIButton()
        button.setTitle("Arm Missiles".uppercased(), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.black)
        button.frame = CGRect(origin: CGPoint(x:670, y: UIScreen.main.bounds.height - 190), size: CGSize(width: 140, height: 40))
        button.titleEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.layer.borderColor = UIColor.red.cgColor
        button.layer.borderWidth = 3
        return button
    }()
    
    var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet weak var sceneView: GameSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DeviceOrientation.shared.set(orientation: .landscapeRight)
        UIApplication.shared.isIdleTimerDisabled = true
        setupTracking()
        sceneView.setup()
        DispatchQueue.main.asyncAfter(deadline: .now() +  1) {
            self.sceneView.addSubview(self.padView1)
            self.sceneView.addSubview(self.padView2)
            self.setupPadScene()
            self.sceneView.addSubview(self.armMissilesButton)
            self.armMissilesButton.addTarget(self, action: #selector(self.didTapUIButton), for: .touchUpInside)
        }
    }
    
    func setupTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
            configuration.sceneReconstruction = sceneReconstruction
        }
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: LocalConstants.environmentalMap) {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        sceneView.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setupPadScene() {
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @objc func didTapUIButton() {
        print("missile arm button tapped")
        DispatchQueue.main.async {
            self.sceneView.armMissiles()
            if self.sceneView.droneSceneView.helicopter.missilesArmed {
                self.armMissilesButton.setTitle("Disarm Missiles".uppercased(), for: .normal)
            } else {
                self.armMissilesButton.setTitle("Arm Missile".uppercased(), for: .normal)
            }
        }
    }
}

// MARK: - ARSCNViewDelegate

extension GameViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session interruption has ended.")
    }
}

// MARK: - JoystickSceneDelegate

extension GameViewController: JoystickSceneDelegate {
    
    func update(xValue: Float, stickNum: Int) {
        if stickNum == 1 {
            let scaled = (xValue) * 0.00025
            sceneView.rotate(value: scaled)
        } else if stickNum == 2 {
            let scaled = -(xValue) * 0.5
            sceneView.moveSides(value: scaled)
        }
    }
    
    func update(yValue: Float, stickNum: Int) {
        if stickNum == 1 {
            let scaled = -(yValue) * 0.5
            sceneView.moveForward(value: scaled)
        } else if stickNum == 2 {
            let scaled = (yValue) * 0.5
            sceneView.changeAltitude(value: scaled)
        }
    }
    
    func tapped() {
        sceneView.shootMissile()
    }
}
