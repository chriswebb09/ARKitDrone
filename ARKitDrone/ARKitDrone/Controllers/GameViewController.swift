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
    
    lazy var padView1: SKView = {
        let view = SKView(frame: CGRect(x:50, y: 30, width:150, height: 150))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var padView2: SKView = {
        let view = SKView(frame: CGRect(x:650, y: UIScreen.main.bounds.height - 200, width:150, height: 150))
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
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
        DeviceOrientation.shared.set(orientation: .landscapeLeft)
        UIApplication.shared.isIdleTimerDisabled = true
        setupTracking()
        sceneView.setup()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.sceneView.addSubview(self.padView1)
            self.sceneView.addSubview(self.padView2)
            self.setupPadScene()
        }
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
        scene.size = CGSize(width: 180, height: 170)
        scene.joystickDelegate = self
        scene.stickNum = 2
        padView1.presentScene(scene)
        padView1.ignoresSiblingOrder = true
        
        let scene2 = JoystickScene()
        scene2.point = CGPoint(x: 0, y: 0)
        scene2.size = CGSize(width: 180, height: 170)
        scene2.joystickDelegate = self
        scene2.stickNum = 1
        padView2.presentScene(scene2)
        padView2.ignoresSiblingOrder = true
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
    
    func update(xValue: Float, stickNum: Int) {
        print(stickNum)
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
        shoot()
    }
    
    func shoot() {
        sceneView.shootMissile()
    }
}
