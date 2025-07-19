/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Indentifies a player in the game.
 */

import Foundation
import MultipeerConnectivity
import simd

struct Player: @unchecked Sendable {
    
    var username: String
    
    init(peerID: MCPeerID) {
        self.username = peerID.displayName
    }
    
    init(username: String) {
        self.username = username
    }
}

extension Player: Hashable {
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.username == rhs.username
    }
    
    func hash(into hasher: inout Hasher) {
        username.hash(into: &hasher)
    }
}
