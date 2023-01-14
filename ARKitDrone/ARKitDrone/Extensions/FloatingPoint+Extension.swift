//
//  FloatingPoint+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

extension FloatingPoint {
    
    var degreesToRadians: Self {
        self * .pi / 180
    }
    
    var radiansToDegrees: Self {
        self * 180 / .pi
    }
}
