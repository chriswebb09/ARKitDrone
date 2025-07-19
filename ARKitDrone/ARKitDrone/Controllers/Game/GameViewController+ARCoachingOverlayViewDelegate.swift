//
//  GameViewController+ARCoachingOverlayViewDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import ARKit
import RealityKit
import UIKit


extension GameViewController: ARCoachingOverlayViewDelegate {
    
    nonisolated func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) { }
    
    nonisolated func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) { }
    
    nonisolated func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) { }
    
    func setupCoachingOverlay() {
        coachingOverlay.session = realityKitView.session
        coachingOverlay.delegate = self
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        realityKitView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: realityKitView.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: realityKitView.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: realityKitView.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: realityKitView.heightAnchor)
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
    func updateFocusSquare(isObjectVisible: Bool) {
        // If game is placed, always hide and don't update
        if game.placed {
            focusSquare.hide()
            print("🎯 Focus square hidden - game is placed")
            return
        }
        
        print("🎯 Focus square update - game.placed: \(game.placed), isObjectVisible: \(isObjectVisible)")
        
        if isObjectVisible || coachingOverlay.isActive {
            focusSquare.hide()
            return
        } else {
            focusSquare.unhide()
        }

        guard let currentFrame = session.currentFrame else { return }
        let camera = currentFrame.camera

        guard case .normal = camera.trackingState else { return }

        guard let query = realityKitView.makeRaycastQuery(
            from: realityKitView.center,
            allowing: .estimatedPlane,
            alignment: .horizontal
        ),
        let result = realityKitView.session.raycast(query).first else {
            return
        }

        guard let anchor = focusSquareAnchor else { return }
        anchor.transform = Transform(matrix: result.worldTransform)

        let lightweightResult = LightweightRaycastResult(
            worldTransform: result.worldTransform,
            anchor: result.anchor
        )
        focusSquare.updateWithLightweight(result: lightweightResult, camera: camera)
    }
}
