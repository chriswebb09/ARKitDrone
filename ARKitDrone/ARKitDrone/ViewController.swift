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

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var altitudeSlider: UISlider! {
        didSet {
            altitudeSlider.transform =  CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        }
    }
    @IBOutlet weak var sceneView: DroneSceneView!
    @IBOutlet weak var forwardButton: UIButton! {
        didSet {
            let image = forwardButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            forwardButton.setImage(image, for: .normal)
            forwardButton.tintColor = .white
        }
    }
    @IBOutlet weak var reverseButton: UIButton! {
        didSet {
            let image = reverseButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            reverseButton.setImage(image, for: .normal)
            reverseButton.tintColor = .white
        }
    }
    @IBOutlet weak var rightButton: UIButton! {
        didSet {
            let image = rightButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            rightButton.setImage(image, for: .normal)
            rightButton.tintColor = .white
        }
    }
    @IBOutlet weak var leftButton: UIButton! {
        didSet {
            let image = leftButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
            leftButton.setImage(image, for: .normal)
            leftButton.tintColor = .white
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.setupDrone()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    @IBAction func altitudeValueChanged(_ sender: Any) {
        guard let slider = sender as? UISlider else { return }
        sceneView.changeAltitude(value: slider.value)
    }
    
    @IBAction func forwardButtonTapped(_ sender: Any) {
        sceneView.moveForward()
    }
    
    @IBAction func rightButtonTapped(_ sender: Any) {
       sceneView.moveRight()
    }
   
    @IBAction func reverseButtonTapped(_ sender: Any) {
        sceneView.reverse()
    }
    
    @IBAction func leftButtonTapped(_ sender: Any) {
        sceneView.moveLeft()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
