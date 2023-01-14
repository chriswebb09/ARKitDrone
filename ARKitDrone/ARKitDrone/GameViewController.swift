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
//        let originVisualizationNode = createAxesNode(quiverLength: 0.1, quiverThickness: 1.0)
//        self.sceneView.scene.rootNode.addChildNode(originVisualizationNode)
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
    func shoot() {
        sceneView.shootMissile()
    }
    
    func update(velocity: Float) {
        let scaled = (velocity) * 0.5
        sceneView.moveForward(value: scaled)
    }
    
    func update(altitude: Float) {
        let scaled = -(altitude) * 0.5
        sceneView.changeAltitude(value: scaled)
    }
    
    func update(rotate: Float) {
        let scaled = (rotate) * -0.00025
        sceneView.rotate(value: scaled)
    }
    
    func update(sides: Float) {
        let scaled = (sides) * -0.5
        sceneView.moveSides(value: scaled)
    }
}


extension SCNMaterial {

    static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.isDoubleSided = true
        if respondsToLighting {
            material.locksAmbientWithDiffuse = true
        } else {
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = diffuse
        }
        return material
    }
}

// MARK: - Simple geometries

func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
    let quiverThickness = (quiverLength / 50.0) * quiverThickness
    let chamferRadius = quiverThickness / 2.0

    let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness, length: quiverThickness, chamferRadius: chamferRadius)
    xQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
    let xQuiverNode = SCNNode(geometry: xQuiverBox)
    xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)

    let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength, length: quiverThickness, chamferRadius: chamferRadius)
    yQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.green, respondsToLighting: false)]
    let yQuiverNode = SCNNode(geometry: yQuiverBox)
    yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)

    let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness, length: quiverLength, chamferRadius: chamferRadius)
    zQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.blue, respondsToLighting: false)]
    let zQuiverNode = SCNNode(geometry: zQuiverBox)
    zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))

    let quiverNode = SCNNode()
    quiverNode.addChildNode(xQuiverNode)
    quiverNode.addChildNode(yQuiverNode)
    quiverNode.addChildNode(zQuiverNode)
    quiverNode.name = "Axes"
    return quiverNode
}


