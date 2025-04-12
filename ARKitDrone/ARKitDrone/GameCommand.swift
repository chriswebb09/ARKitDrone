/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Representations for game events, related data, and their encoding.
*/

import Foundation
import simd
import SceneKit
import ARKit

class BoardAnchor: ARAnchor, @unchecked Sendable {
    let size: CGSize
    
    init(transform: float4x4, size: CGSize) {
        self.size = size
        super.init(name: "Board", transform: transform)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.size = aDecoder.decodeCGSize(forKey: "size")
        super.init(coder: aDecoder)
    }
    
    // this is guaranteed to be called with something of the same class
    required init(anchor: ARAnchor) {
        let other = anchor as! BoardAnchor
        self.size = other.size
        super.init(anchor: other)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(size, forKey: "size")
    }
}

extension ARWorldMap {
    var boardAnchor: BoardAnchor? {
        return anchors.compactMap { $0 as? BoardAnchor }.first
    }
    
    var keyPositionAnchors: [KeyPositionAnchor] {
        return anchors.compactMap { $0 as? KeyPositionAnchor }
    }
}

import ARKit

class KeyPositionAnchor: ARAnchor, @unchecked Sendable {
    let image: UIImage
    let mappingStatus: ARFrame.WorldMappingStatus
    
    init(image: UIImage, transform: float4x4, mappingStatus: ARFrame.WorldMappingStatus) {
        self.image = image
        self.mappingStatus = mappingStatus
        super.init(name: "KeyPosition", transform: transform)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let image = aDecoder.decodeObject(of: UIImage.self, forKey: "image") {
            self.image = image
            let mappingValue = aDecoder.decodeInteger(forKey: "mappingStatus")
            self.mappingStatus = ARFrame.WorldMappingStatus(rawValue: mappingValue) ?? .notAvailable
        } else {
            return nil
        }
        super.init(coder: aDecoder)
    }
    
    // this is guaranteed to be called with something of the same class
    required init(anchor: ARAnchor) {
        let other = anchor as! KeyPositionAnchor
        self.image = other.image
        self.mappingStatus = other.mappingStatus
        super.init(anchor: other)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(image, forKey: "image")
        aCoder.encode(mappingStatus.rawValue, forKey: "mappingStatus")
    }
}

/// - Tag: GameCommand
struct GameCommand {
    var player: Player?
    var action: Action
}

extension SIMD3<Float>: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let x = try bitStream.readFloat()
        let y = try bitStream.readFloat()
        let z = try bitStream.readFloat()
        self.init(x, y, z)
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendFloat(x)
        bitStream.appendFloat(y)
        bitStream.appendFloat(z)
    }
}

extension SIMD4<Float>: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let x = try bitStream.readFloat()
        let y = try bitStream.readFloat()
        let z = try bitStream.readFloat()
        let w = try bitStream.readFloat()
        self.init(x, y, z, w)
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        bitStream.appendFloat(x)
        bitStream.appendFloat(y)
        bitStream.appendFloat(z)
        bitStream.appendFloat(w)
    }
}

extension float4x4: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        self.init()
        self.columns.0 = try SIMD4<Float>(from: &bitStream)
        self.columns.1 = try SIMD4<Float>(from: &bitStream)
        self.columns.2 = try SIMD4<Float>(from: &bitStream)
        self.columns.3 = try SIMD4<Float>(from: &bitStream)
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        columns.0.encode(to: &bitStream)
        columns.1.encode(to: &bitStream)
        columns.2.encode(to: &bitStream)
        columns.3.encode(to: &bitStream)
    }
}

extension String: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let data = try bitStream.readData()
        if let value = String(data: data, encoding: .utf8) {
            self = value
        } else {
            throw BitStreamError.encodingError
        }
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        if let data = data(using: .utf8) {
            bitStream.append(data)
        } else {
            throw BitStreamError.encodingError
        }
    }
}

enum GameBoardLocation: BitStreamCodable {
    case worldMapData(Data)
    case manual
    
    enum CodingKey: UInt32, CaseIterable {
        case worldMapData
        case manual
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .worldMapData:
            let data = try bitStream.readData()
            self = .worldMapData(data)
        case .manual:
            self = .manual
        }
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .worldMapData(let data):
            bitStream.appendEnum(CodingKey.worldMapData)
            bitStream.append(data)
        case .manual:
            bitStream.appendEnum(CodingKey.manual)
        }
    }
}

enum BoardSetupAction: BitStreamCodable {
    case requestBoardLocation
    case boardLocation(GameBoardLocation)
    
    enum CodingKey: UInt32, CaseIterable {
        case requestBoardLocation
        case boardLocation
        
    }
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .requestBoardLocation:
            self = .requestBoardLocation
        case .boardLocation:
            let location = try GameBoardLocation(from: &bitStream)
            self = .boardLocation(location)
        }
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
        case .requestBoardLocation:
            bitStream.appendEnum(CodingKey.requestBoardLocation)
        case .boardLocation(let location):
            bitStream.appendEnum(CodingKey.boardLocation)
            location.encode(to: &bitStream)
        }
    }
}


struct GameVelocity {
    var vector: SIMD3<Float>
    static var zero: GameVelocity { return GameVelocity(vector: SIMD3<Float>()) }
}

extension GameVelocity: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        vector = try SIMD3<Float>(from: &bitStream)
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        vector.encode(to: &bitStream)
    }
}

private let velocityCompressor = FloatCompressor(minValue: -50.0, maxValue: 50.0, bits: 16)
private let angularVelocityAxisCompressor = FloatCompressor(minValue: -1.0, maxValue: 1.0, bits: 12)


enum Direction: BitStreamCodable {
    case forward
    case altitude
    case rotation
    case side
    
    enum CodingKey: UInt32, CaseIterable {
        case forward
        case altitude
        case rotation
        case side
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
            
        case .forward:
            self = .forward
        case .altitude:
            self = .altitude
        case .rotation:
            self = .rotation
        case .side:
            self = .side
        }
//        case .requestBoardLocation:
//            self = .requestBoardLocation
//        case .boardLocation:
//            let location = try GameBoardLocation(from: &bitStream)
//            self = .boardLocation(location)
//        }
    }
    
    func encode(to bitStream: inout WritableBitStream) {
        switch self {
//        case .requestBoardLocation:
//            bitStream.appendEnum(CodingKey.requestBoardLocation)
//        case .boardLocation(let location):
//            bitStream.appendEnum(CodingKey.boardLocation)
//            location.encode(to: &bitStream)
        case .forward:
            bitStream.appendEnum(CodingKey.forward)
        case .altitude:
            bitStream.appendEnum(CodingKey.altitude)
        case .rotation:
            bitStream.appendEnum(CodingKey.rotation)
        case .side:
            bitStream.appendEnum(CodingKey.side)
        }
    }
}

struct MoveData {
    var velocity: GameVelocity
    var angular: Float
    var direction: Direction?
}

extension MoveData: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        velocity = try GameVelocity(from: &bitStream)
        direction = try Direction(from: &bitStream)
        angular = try bitStream.readFloat()
    }

    func encode(to bitStream: inout WritableBitStream) throws {
        velocity.encode(to: &bitStream)
        direction?.encode(to: &bitStream)
        bitStream.appendFloat(angular)
    }
}

struct AddNodeAction {
    var simdWorldTransform: float4x4
    var eulerAngles: SIMD3<Float>
}

extension AddNodeAction: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        simdWorldTransform = try float4x4(from: &bitStream)
        eulerAngles = try SIMD3<Float>(from: &bitStream)
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        simdWorldTransform.encode(to: &bitStream)
        eulerAngles.encode(to: &bitStream)
    }
}

enum GameAction {
    case joyStickMoved(MoveData)
    case movement(MovementSyncData)
    
    private enum CodingKey: UInt32, CaseIterable {
        case move
//        case fire
    }
}

struct CompletedAction {
    var position: SIMD3<Float>
}

extension CompletedAction: BitStreamCodable {
    func encode(to bitStream: inout WritableBitStream) throws {
        position.encode(to: &bitStream)
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        position = try SIMD3<Float>(from: &bitStream)
    }
}

extension GameAction: BitStreamCodable {
    
    func encode(to bitStream: inout WritableBitStream) throws {
        // switch game action
        switch self {
        case .joyStickMoved(let data):
            bitStream.appendEnum(CodingKey.move)
            try data.encode(to: &bitStream)
            
        case .movement(let data):
            bitStream.appendEnum(CodingKey.move)
            try data.encode(to: &bitStream)
        }
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let key: CodingKey = try bitStream.readEnum()
        switch key {
        case .move:
            let data = try MoveData(from: &bitStream)
            self = .joyStickMoved(data)
        }
    }
    
}

enum Action {
    case gameAction(GameAction)
    case boardSetup(BoardSetupAction)
    case addNode(AddNodeAction)
    case completed(CompletedAction)
}

extension Action: BitStreamCodable {
    private enum CodingKey: UInt32, CaseIterable {
        case gameAction
        case boardSetup
        case addTank
        case completed
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        switch self {
        case .gameAction(let gameAction):
            bitStream.appendEnum(CodingKey.gameAction)
            try gameAction.encode(to: &bitStream)
        case .boardSetup(let boardSetup):
            bitStream.appendEnum(CodingKey.boardSetup)
            boardSetup.encode(to: &bitStream)
        case .addNode(let addTankAction):
            bitStream.appendEnum(CodingKey.addTank)
            try addTankAction.encode(to: &bitStream)
        case .completed(let completedAction):
            bitStream.appendEnum(CodingKey.completed)
            try completedAction.encode(to: &bitStream)
        }
    }
    
    init(from bitStream: inout ReadableBitStream) throws {
        let code: CodingKey = try bitStream.readEnum()
        switch code {
        case .gameAction:
            let gameAction = try GameAction(from: &bitStream)
            self = .gameAction(gameAction)
        case .boardSetup:
            let boardAction = try BoardSetupAction(from: &bitStream)
            self = .boardSetup(boardAction)
        case .addTank:
            let addNodeAction = try AddNodeAction(from: &bitStream)
            self = .addNode(addNodeAction)
        case .completed:
            let completedAction = try CompletedAction(from: &bitStream)
            self = .completed(completedAction)
        }
    }
    
}
