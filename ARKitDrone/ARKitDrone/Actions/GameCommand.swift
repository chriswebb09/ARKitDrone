/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Representations for game events, related data, and their encoding.
*/

import Foundation
import simd
import SceneKit
import ARKit

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


private let velocityCompressor = FloatCompressor(minValue: -50.0, maxValue: 50.0, bits: 16)
private let angularVelocityAxisCompressor = FloatCompressor(minValue: -1.0, maxValue: 1.0, bits: 12)
