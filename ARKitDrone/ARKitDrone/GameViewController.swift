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
    
    lazy var padView: SKView = {
        let view = SKView(frame: CGRect(x: 20, y: 500, width: 350, height: 250))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()

    var session: ARSession {
        return sceneView.session
    }
    
    @IBOutlet weak var sceneView: DroneSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        sceneView.setupDrone()
        sceneView.addSubview(padView)
        setupPadScene()
        setupTracking()
    }
    
    func setupTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        let sceneReconstruction: ARWorldTrackingConfiguration.SceneReconstruction = .meshWithClassification
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(sceneReconstruction) {
            configuration.sceneReconstruction = sceneReconstruction
        }
        sceneView.delegate = self
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setupPadScene() {
        let scene = JoystickScene()
        scene.point = CGPoint(x: 0, y: 0)
        scene.size = CGSize(width: 500, height: 400)
        scene.joystickDelegate = self
        padView.presentScene(scene)
        padView.ignoresSiblingOrder = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
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

extension GameViewController: JoystickSceneDelegate {
    func update(velocity: Float) {
        let scaled = -(velocity) * 0.5
        sceneView.moveForward(value: scaled)
    }
    
    func update(altitude: Float) {
        let scaled = -(altitude) * 0.5
        sceneView.changeAltitude(value: scaled)
    }
    
    func update(sides: Float) {
        let scaled = (sides) * 0.00025
        sceneView.moveSide(value: scaled)
    }
    
    func update(moveSides: Float) {
        
    }
}


