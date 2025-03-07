//
//  GameViewController+ARCoachingOverlayViewDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit

extension GameViewController: ARCoachingOverlayViewDelegate {
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) { }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) { }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) { }
    
    func setupCoachingOverlay() {
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        setActivatesAutomatically()
        setGoal()
    }
    
    func setActivatesAutomatically() {
        coachingOverlay.activatesAutomatically = true
    }
    
    func setGoal() {
        coachingOverlay.goal = .horizontalPlane
    }
    
    // MARK: - Focus Square
    
    func updateFocusSquare(isObjectVisible: Bool) {
        if isObjectVisible || coachingOverlay.isActive {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
        }
        if let camera = session.currentFrame?.camera,
           case .normal = camera.trackingState,
           let query = sceneView.getRaycastQuery(),
           let result = sceneView.castRay(for: query).first {
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


