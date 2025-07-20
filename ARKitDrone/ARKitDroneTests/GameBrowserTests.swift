//
//  GameBrowserTests.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//


import Testing
import MultipeerConnectivity
@testable import ARKitDrone

import MultipeerConnectivity

final class MockNearbyServiceBrowser: MCNearbyServiceBrowser {
    
    // We keep the delegate publicly settable (like the real browser)
    override var delegate: MCNearbyServiceBrowserDelegate? {
        get { super.delegate }
        set { super.delegate = newValue }
    }
    
    private(set) var startedBrowsing = false
    private(set) var stoppedBrowsing = false
    
    override func startBrowsingForPeers() {
        startedBrowsing = true
    }
    
    override func stopBrowsingForPeers() {
        stoppedBrowsing = true
    }
    
    private(set) var invitedPeers: [(peerID: MCPeerID, session: MCSession, context: Data?, timeout: TimeInterval)] = []
    
    override func invitePeer(_ peerID: MCPeerID,
                             to session: MCSession,
                             withContext context: Data?,
                             timeout: TimeInterval) {
        invitedPeers.append((peerID, session, context, timeout))
    }
}

struct TestError: Error, CustomStringConvertible {
    let message: String
    init(_ message: String) { self.message = message }
    var description: String { message }
}

struct GameBrowserTests {
    var gameBrowser: GameBrowser!
    var player: Player!
    var delegateMock: GameBrowserDelegateMock!
    var mockBrowser: MockNearbyServiceBrowser!
    
    // Setup before each test (if your framework supports it)
    
    @MainActor
    mutating func setUp() {
        player = Player(username: "TestPlayer")
        mockBrowser = MockNearbyServiceBrowser(peer: MCPeerID(displayName: player.username), serviceType: MultiuserService.playerService)
        gameBrowser = GameBrowser(myself: player, serviceBrowser: mockBrowser)
        gameBrowser.delegate = delegateMock
    }
    @Test
    mutating func testStartBrowsingDoesNotThrow() async throws {
        await setUp()
        gameBrowser.start()  // If this throws, the test will fail automatically
    }
    
    @Test
    mutating func testStopBrowsingDoesNotThrow() async throws {
        await setUp()
        gameBrowser.stop()  // If this throws, the test will automatically fail
    }
    
//    @Test
//    @MainActor
//    func testFoundPeerAddsGameAndCallsDelegate() async throws {
//        let peerID = MCPeerID(displayName: "Opponent")
//        let appId = Bundle.main.appIdentifier ?? "com.example.ARKitDrone"
//
//        let discoveryInfo = [
//            MultiuserAttribute.appIdentifier: appId,
//            MultiuserAttribute.name: "Test Game"
//        ]
//        
//        // Call delegate method directly since serviceBrowser is mocked/injected
//        gameBrowser.browser(
//            mockBrowser, // your injected MockNearbyServiceBrowser
//            foundPeer: peerID,
//            withDiscoveryInfo: discoveryInfo
//        )
//        
//        // Wait for async task in foundPeer
//        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
//        
//        #expect(delegateMock.sawGamesCalled)
//        #expect(delegateMock.sawGames.count == 1)
//        #expect(delegateMock.sawGames.first?.name == "Test Game")
//        #expect(delegateMock.sawGames.first?.host.username == "Opponent")
//    }
//    
//    @Test
//    @MainActor
//    func testFoundPeerIgnoresIfAppIdentifierMismatch() async throws {
//        let peerID = MCPeerID(displayName: "Opponent")
//        let appId = Bundle.main.appIdentifier ?? "com.example.ARKitDrone"
//
//        let discoveryInfo = [
//            MultiuserAttribute.appIdentifier: appId,
//            MultiuserAttribute.name: "Test Game"
//        ]
//        gameBrowser.browser(
//            mockBrowser,
//            foundPeer: peerID,
//            withDiscoveryInfo: discoveryInfo
//        )
//        
//        #expect(!delegateMock.sawGamesCalled)
//        #expect(gameBrowser.games.isEmpty)
//    }
    
//    @Test
//    func testFoundPeerIgnoresSelf() async throws {
//        let player = Player(username: "Me")
//        let peerID = MCPeerID(displayName: player.username)
//        let appId = Bundle.main.appIdentifier ?? "com.example.ARKitDrone"
//
//        let discoveryInfo = [
//            MultiuserAttribute.appIdentifier: appId,
//            MultiuserAttribute.name: "Test Game"
//        ]
//        
//        gameBrowser.browser(
//            mockBrowser,
//            foundPeer: peerID,
//            withDiscoveryInfo: discoveryInfo
//        )
//        
//        //        #expectFalse(delegateMock.sawGamesCalled)
//        #expect(gameBrowser.games.isEmpty)
//    }
    
//    @Test
//    @MainActor
//    func testLostPeerRemovesGameAndCallsDelegate() async throws {
//        let playerHost = Player(username: "Opponent")
//        let game = NetworkGame(host: playerHost, name: "Test Game")
//        if let firstGame = delegateMock.sawGames.first {
//            #expect(firstGame.name == "Test Game")
//            gameBrowser.games.insert(game)
//        } else {
//            throw TestError("No games")
//        }
//  
//        let peerID = MCPeerID(displayName: "Opponent")
//        gameBrowser.browser(mockBrowser, lostPeer: peerID)
//        
//        try await Task.sleep(nanoseconds: 100_000_000)
//        
//        #expect(delegateMock.sawGamesCalled)
//        #expect(gameBrowser.games.isEmpty)
//    }
    
//    @Test
//    func testJoinGameReturnsSessionForExistingGame() async throws {
//        let hostPlayer = Player(username: "HostPlayer")
//        let game = NetworkGame(host: hostPlayer, name: "Host Game")
//        gameBrowser.games.insert(game)
//        
//        let session = gameBrowser.join(game: game)
//        #expect((session == nil))
//        #expect(session?.host.username == hostPlayer.username)
//        #expect(!session!.isServer)
//    }
//    
//    @Test
//    func testJoinGameReturnsNilForUnknownGame() async throws {
//        let unknownGame = NetworkGame(host: Player(username: "Unknown"), name: "Unknown Game")
//        gameBrowser.games = Set([unknownGame])
//        let session = gameBrowser.join(game: unknownGame)
//        #expect(session == nil)
//    }
}

// Example mock for the delegate
class GameBrowserDelegateMock: GameBrowserDelegate {
    var sawGamesCalled = false
    var sawGames: [NetworkGame] = []
    
    func gameBrowser(_ browser: GameBrowser, sawGames games: [NetworkGame]) {
        sawGamesCalled = true
        sawGames = games
    }
}
