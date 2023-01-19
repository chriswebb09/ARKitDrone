//
//  UIView+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/16/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

// https://medium.com/@mail2sajalkaushik/swift-creating-custom-neumorphic-view-using-uikit-fe94c60aedc1

extension UIColor {
    static let offWhite = UIColor.init(red: 225/255, green: 225/255, blue: 235/255, alpha: 1)
}

extension UIView {
    
    func setshadow() {
        let darkShadow = CALayer()
        let lightShadow = CALayer()
        darkShadow.frame = bounds
        darkShadow.cornerRadius = 15
        darkShadow.backgroundColor = UIColor.offWhite.cgColor
        darkShadow.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
        darkShadow.shadowOffset = CGSize(width: 10, height: 10)
        darkShadow.shadowOpacity = 1
        darkShadow.shadowRadius = 15
        layer.insertSublayer(darkShadow, at: 0)
        lightShadow.frame = bounds
        lightShadow.cornerRadius = 15
        lightShadow.backgroundColor = UIColor.offWhite.cgColor
        lightShadow.shadowColor = UIColor.white.withAlphaComponent(0.9).cgColor
        lightShadow.shadowOffset = CGSize(width: -5, height: -5)
        lightShadow.shadowOpacity = 1
        lightShadow.shadowRadius = 15
        layer.insertSublayer(lightShadow, at: 0)
    }
}


