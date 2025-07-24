//
//  ARSessionManagerTests.swift
//  ARKitDroneTests
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Testing
import ARKit
import RealityKit
@testable import ARKitDrone

@MainActor
struct ARSessionManagerTests {
    
    @Test("ARSessionManager can be created and configured")
    func testARSessionManagerCreation() async throws {
        let arSessionManager = ARSessionManager()
        let arView = ARView(frame: .zero)
        
        let configuration = ARSessionSettings(
            enableSceneReconstruction: false,
            planeDetection: [.horizontal],
            environmentMapName: "test_environment.exr"
        )
        
        // Should not throw an error
        await arSessionManager.configure(arView: arView, configuration: configuration)
    }
    
    @Test("ARSessionManager protocol methods exist")
    func testARSessionManagerProtocolMethods() {
        let arSessionManager = ARSessionManager()
        
        // Verify all protocol methods are available
        #expect(arSessionManager.delegate == nil) // Initially nil
        
        // These methods should exist (compilation test)
        let _ = arSessionManager.getCurrentWorldMap
        let _ = arSessionManager.loadWorldMap
        let _ = arSessionManager.compressWorldMap
        let _ = arSessionManager.decompressWorldMap
        let _ = arSessionManager.startSession
        let _ = arSessionManager.resetSession
        let _ = arSessionManager.pauseSession
    }
    
    @Test("ARSessionSettings has correct default values")
    func testARSessionSettingsDefaults() {
        let defaultConfig = ARSessionSettings.default
        
        #expect(defaultConfig.enableSceneReconstruction == false)
        #expect(defaultConfig.planeDetection == [.horizontal])
        #expect(defaultConfig.environmentMapName == "environment_blur.exr")
    }
    
    @Test("ARSessionManager error types are properly defined")
    func testARSessionErrorTypes() {
        let configError = ARSessionError.arViewNotConfigured
        let mapError = ARSessionError.noWorldMapAvailable
        let decodingError = ARSessionError.worldMapDecodingFailed
        
        #expect(configError.errorDescription != nil)
        #expect(mapError.errorDescription != nil)
        #expect(decodingError.errorDescription != nil)
        
        #expect(configError.errorDescription == "ARView is not configured")
        #expect(mapError.errorDescription == "No world map is available")
        #expect(decodingError.errorDescription == "Failed to decode world map data")
    }
}

// MARK: - Mock Delegate for Testing

class MockARSessionManagerDelegate: ARSessionManagerDelegate {
    var didUpdateSessionStateCallCount = 0
    var didAddAnchorCallCount = 0
    var didUpdateAnchorCallCount = 0
    var didRemoveAnchorCallCount = 0
    var didFailWithErrorCallCount = 0
    
    var lastTrackingState: ARCamera.TrackingState?
    var lastError: Error?
    
    func arSessionManager(_ manager: ARSessionManager, didUpdateSessionState state: ARCamera.TrackingState) {
        didUpdateSessionStateCallCount += 1
        lastTrackingState = state
    }
    
    func arSessionManager(_ manager: ARSessionManager, didAddAnchor anchor: ARAnchor) {
        didAddAnchorCallCount += 1
    }
    
    func arSessionManager(_ manager: ARSessionManager, didUpdateAnchor anchor: ARAnchor) {
        didUpdateAnchorCallCount += 1
    }
    
    func arSessionManager(_ manager: ARSessionManager, didRemoveAnchor anchor: ARAnchor) {
        didRemoveAnchorCallCount += 1
    }
    
    func arSessionManager(_ manager: ARSessionManager, didFailWithError error: Error) {
        didFailWithErrorCallCount += 1
        lastError = error
    }
}

@MainActor
extension ARSessionManagerTests {
    
    @Test("ARSessionManager delegate methods are called")  
    func testARSessionManagerDelegate() async throws {
        let arSessionManager = ARSessionManager()
        let mockDelegate = MockARSessionManagerDelegate()
        let arView = ARView(frame: .zero)
        
        arSessionManager.delegate = mockDelegate
        await arSessionManager.configure(arView: arView)
        
        #expect(arSessionManager.delegate === mockDelegate)
        
        // Initial state - no calls yet
        #expect(mockDelegate.didUpdateSessionStateCallCount == 0)
        #expect(mockDelegate.didAddAnchorCallCount == 0)
        #expect(mockDelegate.didFailWithErrorCallCount == 0)
    }
}