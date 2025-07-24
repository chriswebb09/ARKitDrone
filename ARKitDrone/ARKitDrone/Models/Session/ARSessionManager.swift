//
//  ARSessionManager.swift
//  ARKitDrone
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import ARKit
import RealityKit
import os.log

// MARK: - AR Session Configuration

struct ARSessionSettings {
    let enableSceneReconstruction: Bool
    let planeDetection: ARWorldTrackingConfiguration.PlaneDetection
    let environmentMapName: String
    
    static let `default` = ARSessionSettings(
        enableSceneReconstruction: false,
        planeDetection: [.horizontal],
        environmentMapName: "environment_blur.exr"
    )
}

// MARK: - AR Session Manager Delegate (simplified)

@MainActor
protocol ARSessionManagerDelegate: AnyObject {
    func arSessionManager(_ manager: ARSessionManager, didUpdateSessionState state: ARCamera.TrackingState)
    func arSessionManager(_ manager: ARSessionManager, didAddAnchor anchor: ARAnchor)
    func arSessionManager(_ manager: ARSessionManager, didUpdateAnchor anchor: ARAnchor)
    func arSessionManager(_ manager: ARSessionManager, didRemoveAnchor anchor: ARAnchor)
    func arSessionManager(_ manager: ARSessionManager, didFailWithError error: Error)
}

// MARK: - Default Implementation

extension ARSessionManagerDelegate {
    func arSessionManager(_ manager: ARSessionManager, didUpdateSessionState state: ARCamera.TrackingState) {}
    func arSessionManager(_ manager: ARSessionManager, didAddAnchor anchor: ARAnchor) {}
    func arSessionManager(_ manager: ARSessionManager, didUpdateAnchor anchor: ARAnchor) {}
    func arSessionManager(_ manager: ARSessionManager, didRemoveAnchor anchor: ARAnchor) {}
    func arSessionManager(_ manager: ARSessionManager, didFailWithError error: Error) {}
}

// MARK: - Concrete AR Session Manager

@MainActor
class ARSessionManager: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: ARSessionManagerDelegate?
    
    private weak var arView: ARView?
    private var currentConfiguration: ARSessionSettings = .default
    private var targetWorldMap: ARWorldMap?
    
    // MARK: - Configuration
    
    func configure(arView: ARView, configuration: ARSessionSettings = .default) async {
        self.arView = arView
        self.currentConfiguration = configuration
        
        // Set up session delegate
        arView.session.delegate = self
        
        os_log(.info, "ARSessionManager configured with scene reconstruction: %@", 
               configuration.enableSceneReconstruction ? "enabled" : "disabled")
    }
    
    // MARK: - Session Management
    
    func startSession(with options: ARSession.RunOptions) async {
        guard let arView = arView else {
            os_log(.error, "ARView not configured")
            return
        }
        
        let config = createARConfiguration()
        
        os_log(.info, "Starting AR session with configuration")
        arView.session.run(config, options: options)
        
        // Set up environment lighting if needed
        if !currentConfiguration.environmentMapName.isEmpty {
            try? await setEnvironmentLighting(resourceName: currentConfiguration.environmentMapName)
        }
    }
    
    func resetSession() async {
        guard let arView = arView else { return }
        
        let config = createARConfiguration()
        
        os_log(.info, "Resetting AR session")
        arView.automaticallyConfigureSession = false
        arView.environment.sceneUnderstanding.options = []
        
        arView.session.run(config, options: [
            .resetTracking,
            .removeExistingAnchors,
            .resetSceneReconstruction,
            .stopTrackedRaycasts
        ])
    }
    
    func pauseSession() {
        guard let arView = arView else { return }
        
        os_log(.info, "Pausing AR session")
        arView.session.pause()
    }
    
    // MARK: - World Map Management
    
    func getCurrentWorldMap() async throws -> ARWorldMap {
        guard let arView = arView else {
            throw ARSessionError.arViewNotConfigured
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            arView.session.getCurrentWorldMap { worldMap, error in
                if let error = error {
                    os_log(.error, "Failed to get current world map: %{public}@", error.localizedDescription)
                    continuation.resume(throwing: error)
                } else if let worldMap = worldMap {
                    os_log(.info, "Successfully retrieved current world map")
                    continuation.resume(returning: worldMap)
                } else {
                    os_log(.error, "No world map returned")
                    continuation.resume(throwing: ARSessionError.noWorldMapAvailable)
                }
            }
        }
    }
    
    func loadWorldMap(from data: Data) async throws {
        guard let arView = arView else {
            throw ARSessionError.arViewNotConfigured
        }
        
        os_log(.info, "Loading world map from data")
        
        // Decompress and unarchive the world map
        let worldMap = try await decompressWorldMap(from: data)
        
        // Store the target world map
        self.targetWorldMap = worldMap
        
        // Create configuration with the loaded world map
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        configuration.planeDetection = currentConfiguration.planeDetection
        
        if currentConfiguration.enableSceneReconstruction {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                configuration.sceneReconstruction = .meshWithClassification
                configuration.frameSemantics = .sceneDepth
            }
        }
        
        // Configure AR view
        arView.automaticallyConfigureSession = false
        
        // Run the session with the loaded world map
        arView.session.run(configuration, options: [
            .resetTracking,
            .removeExistingAnchors,
            .resetSceneReconstruction,
            .stopTrackedRaycasts
        ])
        
        os_log(.info, "World map loaded successfully")
        
        // Set up environment lighting
        if !currentConfiguration.environmentMapName.isEmpty {
            try await setEnvironmentLighting(resourceName: currentConfiguration.environmentMapName)
        }
    }
    
    func compressWorldMap(_ map: ARWorldMap) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                    os_log(.info, "World map archived, size: %d bytes", data.count)
                    
                    let compressedData = data.compressed()
                    os_log(.info, "World map compressed to: %d bytes", compressedData.count)
                    
                    continuation.resume(returning: compressedData)
                } catch {
                    os_log(.error, "Failed to compress world map: %{public}@", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func decompressWorldMap(from data: Data) async throws -> ARWorldMap {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    // Decompress the data
                    let uncompressedData = try data.decompressed()
                    
                    // Unarchive the ARWorldMap
                    guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(
                        ofClass: ARWorldMap.self,
                        from: uncompressedData
                    ) else {
                        throw ARSessionError.worldMapDecodingFailed
                    }
                    
                    os_log(.info, "World map decompressed and decoded successfully")
                    continuation.resume(returning: worldMap)
                } catch {
                    os_log(.error, "Failed to decompress world map: %{public}@", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Environment Setup
    
    func setEnvironmentLighting(resourceName: String) async throws {
        guard let arView = arView else {
            throw ARSessionError.arViewNotConfigured
        }
        
        do {
            let environmentResource = try await EnvironmentResource(named: resourceName)
            arView.environment.lighting.resource = environmentResource
            os_log(.info, "Environment lighting set successfully")
        } catch {
            os_log(.error, "Failed to load environment resource '%{public}@': %{public}@", 
                   resourceName, error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func createARConfiguration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = currentConfiguration.planeDetection
        
        if currentConfiguration.enableSceneReconstruction {
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
                config.sceneReconstruction = .meshWithClassification
                config.frameSemantics = .sceneDepth
            }
        }
        
        return config
    }
    
    // MARK: - World Map Data Helpers
    
    func getCurrentWorldMapData() async throws -> Data {
        // Use existing target world map if available, otherwise get current
        let worldMap: ARWorldMap
        
        if let targetWorldMap = targetWorldMap {
            os_log(.info, "Using existing target world map")
            worldMap = targetWorldMap
        } else {
            os_log(.info, "Getting current world map from AR session")
            worldMap = try await getCurrentWorldMap()
        }
        
        return try await compressWorldMap(worldMap)
    }
}

// MARK: - ARSessionDelegate

extension ARSessionManager: ARSessionDelegate {
    
    nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                delegate?.arSessionManager(self, didAddAnchor: anchor)
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                delegate?.arSessionManager(self, didUpdateAnchor: anchor)
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        Task { @MainActor in
            for anchor in anchors {
                delegate?.arSessionManager(self, didRemoveAnchor: anchor)
            }
        }
    }
    
    nonisolated func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        Task { @MainActor in
            delegate?.arSessionManager(self, didUpdateSessionState: camera.trackingState)
        }
    }
    
    nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
        os_log(.error, "AR session failed with error: %{public}@", error.localizedDescription)
        Task { @MainActor in
            delegate?.arSessionManager(self, didFailWithError: error)
        }
    }
}

// MARK: - Error Types

enum ARSessionError: LocalizedError {
    case arViewNotConfigured
    case noWorldMapAvailable
    case worldMapDecodingFailed
    
    var errorDescription: String? {
        switch self {
        case .arViewNotConfigured:
            return "ARView is not configured"
        case .noWorldMapAvailable:
            return "No world map is available"
        case .worldMapDecodingFailed:
            return "Failed to decode world map data"
        }
    }
}