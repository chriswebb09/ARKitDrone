//
//  UIView+Neumorphic.swift
//  ARKitDrone
//
//  Created by Claude on 7/19/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

extension UIView {
    
    /// Adds neumorphic shadow effect using the existing setshadow implementation
    func addNeumorphicShadow(isInset: Bool = false) {
        if isInset {
            addInsetNeumorphicShadow()
        } else {
            // Use existing setshadow method for outset shadows
            setshadow()
        }
    }
    
    private func addInsetNeumorphicShadow() {
        // Create inset shadow effect for container views
        let innerShadow = CALayer()
        innerShadow.frame = bounds
        innerShadow.cornerRadius = layer.cornerRadius
        innerShadow.masksToBounds = true
        
        // Create path for inner shadow
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius)
        let cutout = UIBezierPath(roundedRect: bounds.insetBy(dx: -20, dy: -20), cornerRadius: layer.cornerRadius)
        path.append(cutout)
        path.usesEvenOddFillRule = true
        
        let innerShadowLayer = CAShapeLayer()
        innerShadowLayer.path = path.cgPath
        innerShadowLayer.fillRule = .evenOdd
        innerShadowLayer.fillColor = backgroundColor?.cgColor
        innerShadowLayer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
        innerShadowLayer.shadowOffset = CGSize(width: 2, height: 2)
        innerShadowLayer.shadowOpacity = 1
        innerShadowLayer.shadowRadius = 5
        
        innerShadow.addSublayer(innerShadowLayer)
        layer.insertSublayer(innerShadow, at: 0)
    }
}

extension UIButton {
    
    /// Adds touch animation for neumorphic buttons
    func addNeumorphicTouchAnimation() {
        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func buttonTouchDown() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.transform = CGAffineTransform(scaleX: 0.96, scaleY: 0.96)
            self.alpha = 0.8
        }
    }
    
    @objc private func buttonTouchUp() {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .curveEaseInOut]) {
            self.transform = CGAffineTransform.identity
            self.alpha = 1.0
        }
    }
}