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
    
    let updateQueue = DispatchQueue(label: "com.example.apple-samplecode.arkitexample.serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    var focusSquare = FocusSquare()
    
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
        configuration.planeDetection = [.horizontal, .vertical]
        if #available(iOS 12.0, *) {
            configuration.environmentTexturing = .automatic
        }
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func setupPadScene() {
        let scene = JoystickSKScene()
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
    
    // MARK: - Focus Square

    func updateFocusSquare(isObjectVisible: Bool) {
        // Perform ray casting only when ARKit tracking is in a good state.
        if let camera = session.currentFrame?.camera, case .normal = camera.trackingState, let query = sceneView.getRaycastQuery(), let result = sceneView.castRay(for: query).first {
            updateQueue.async {
                self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
            }
        } else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
        }
    }
}

// MARK: - ARSCNViewDelegate

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare(isObjectVisible: true)
        }
    }
    
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
}

extension GameViewController: ARSessionDelegate {
    
}

