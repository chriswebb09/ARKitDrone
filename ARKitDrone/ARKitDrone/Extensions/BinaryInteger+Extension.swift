//
//  BinaryInteger+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

extension BinaryInteger {
    var degreesToRadians: CGFloat {
        CGFloat(self) * .pi / 180
    }
}
