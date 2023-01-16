//
//  HelicopterCapable.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 1/14/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

protocol HelicopterCapable: AnyObject {
    func rotate(value: Float)
    func moveForward(value: Float)
    func shootMissile()
    func changeAltitude(value: Float)
    func moveSides(value: Float)
}
