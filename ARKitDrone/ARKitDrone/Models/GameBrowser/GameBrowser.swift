/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Finds games in progress on the local network.
 */

import Foundation
import MultipeerConnectivity
import os.log

class GameBrowser: NSObject, @unchecked Sendable {
    
    private let myself: Player
    private let serviceBrowser: MCNearbyServiceBrowser
    
    weak var delegate: GameBrowserDelegate?
    
    fileprivate var games: Set<NetworkGame> = []
    
    init(myself: Player) {
        self.myself = myself
        let peer = MCPeerID(displayName: myself.username)
        self.serviceBrowser = MCNearbyServiceBrowser(
            peer: peer,
            serviceType: MultiuserService.playerService
        )
        super.init()
        self.serviceBrowser.delegate = self
    }
    
    func start() {
        os_log(.info, "looking for peers")
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stop() {
        os_log(.info, "stopping the search for peers")
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func join(game: NetworkGame) -> NetworkSession? {
        guard games.contains(game) else { return nil }
        let session = NetworkSession(
            myself: myself,
            asServer: false,
            host: game.host
        )
        let hostId = MCPeerID(displayName: game.host.username)
        serviceBrowser.invitePeer(
            hostId,
            to: session.session,
            withContext: nil,
            timeout: 30
        )
        return session
    }
}

/// - Tag: GameBrowser-MCNearbyServiceBrowserDelegate
extension GameBrowser: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        os_log(.info, "found peer %@", peerID)
        guard let appIdentifier = info?[MultiuserAttribute.appIdentifier],
              appIdentifier == Bundle.main.appIdentifier else {
            os_log(.info, "peer appIdentifier %s doesn't match, ignoring", info?[MultiuserAttribute.appIdentifier] ?? "(nil)")
            return
        }
        guard peerID != MCPeerID(displayName: myself.username) else {
            os_log(.info, "found myself, ignoring")
            return
        }
        let peerIDName = peerID.displayName
        let capturedInfo = info
        Task { @MainActor in
            let peerIDCopy = MCPeerID(displayName: peerIDName)
            let player = Player(peerID: peerIDCopy)
            let gameName = capturedInfo?[MultiuserAttribute.name]
            let game = NetworkGame(
                host: player,
                name: gameName
            )
            self.games.insert(game)
            self.delegate?.gameBrowser(self, sawGames: Array(self.games))
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        os_log(.info, "lost peer id %@", peerID)
        let peerIDName = peerID.displayName

        Task { @MainActor in
            self.games = self.games.filter { $0.host.username != peerIDName }
            self.delegate?.gameBrowser(self, sawGames: Array(self.games))
        }
//        let capturedPeerID = peerID
//        Task { @MainActor in
//            self.games = self.games.filter { $0.host.username != capturedPeerID.displayName }
//            self.delegate?.gameBrowser(
//                self,
//                sawGames: Array(self.games)
//            )
//        }
    }
    
    func refresh() {
        Task { @MainActor in
            delegate?.gameBrowser(self, sawGames: Array(games))
        }
    }
}
