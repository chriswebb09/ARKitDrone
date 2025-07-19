//
//  ModelLoadError.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/19/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation

enum ModelLoadError: Error {
    case fileNotFound(String)
    case loadingFailed(String)
}

