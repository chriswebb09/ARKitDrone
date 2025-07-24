//
//  SyncDataStructures.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/20/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import simd

extension WritableBitStream {
    mutating func appendFloat64(_ value: Double) {
        var float = value.bitPattern.littleEndian
        let bytes = withUnsafeBytes(of: &float) { Array($0) }
        appendBytes(bytes)
    }
}

extension simd_quatf: BitStreamCodable {
    init(from bitStream: inout ReadableBitStream) throws {
        let x = try bitStream.readFloat32()
        let y = try bitStream.readFloat32()
        let z = try bitStream.readFloat32()
        let w = try bitStream.readFloat32()
        self.init(ix: x, iy: y, iz: z, r: w)
    }
    
    func encode(to bitStream: inout WritableBitStream) throws {
        try bitStream.appendFloat32(imag.x)
        try bitStream.appendFloat32(imag.y)
        try bitStream.appendFloat32(imag.z)
        try bitStream.appendFloat32(real)
    }
}

extension WritableBitStream {
    mutating func appendFloat32(_ value: Float) throws {
        var bitPattern = value.bitPattern.littleEndian
        let bytes = withUnsafeBytes(of: &bitPattern) { Array($0) }
        appendBytes(bytes)
    }
}
