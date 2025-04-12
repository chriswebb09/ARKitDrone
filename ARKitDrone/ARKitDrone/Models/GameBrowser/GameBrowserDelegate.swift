//
//  GameBrowserDelegate.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 4/12/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//
import UIKit

protocol GameBrowserDelegate: AnyObject {
    func gameBrowser(_ browser: GameBrowser, sawGames: [NetworkGame])
}

