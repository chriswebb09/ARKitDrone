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
    
    @IBOutlet weak var sceneView: DroneSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.setupDrone()
        sceneView.addSubview(padView)
        setupPadScene()
    }
    
    func setupPadScene() {
        let scene = JoystickSKScene()
        scene.point = CGPoint(x: 0, y: 0)
        scene.size = CGSize(width: 500, height: 400)
        scene.joystickDelegate = self
        padView.presentScene(scene)
        padView.ignoresSiblingOrder = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
}

// MARK: - ARSCNViewDelegate

extension GameViewController: ARSCNViewDelegate {
    
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

extension GameViewController: JoystickSKSceneDelegate {
    func update(velocity: Float) {
        let scaled = (-1 * velocity) * 0.006
        sceneView.moveForward(value: scaled)
    }
    
    func update(altitude: Float) {
        let scaled = (-1 * altitude) * 0.009
        sceneView.changeAltitude(value: scaled)
    }
    
    func update(sides: Float) {
        let scaled = (-1 * sides) * 0.00005
        sceneView.moveSide(value: scaled)
    }
}



