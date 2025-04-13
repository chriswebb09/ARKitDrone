//
//  NetworkSessionDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//
import Foundation

protocol NetworkSessionDelegate: AnyObject {
    func networkSession(_ session: NetworkSession, received command: GameCommand)
    func networkSession(_ session: NetworkSession, joining player: Player)
    func networkSession(_ session: NetworkSession, leaving player: Player)
}
