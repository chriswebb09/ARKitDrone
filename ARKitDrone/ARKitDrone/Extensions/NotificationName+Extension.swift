//
//  NotificationName+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let missileCanHit = Notification.Name("MissileCanHit")
    static let updateScore = Notification.Name("UpdateScore")
}


var joystickNotificationName = NSNotification.Name("joystickNotificationName")
let joystickVelocityMultiplier: CGFloat = 0.00006
