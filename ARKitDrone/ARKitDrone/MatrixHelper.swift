//
//  MatrixHelper.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 12/30/22.
//  Copyright © 2022 Christopher Webb-Orenstein. All rights reserved.
//


import Foundation
import GLKit
import SceneKit

class MatrixHelper {
    
    static func transform(rotationY: Float, distance: Int) -> SCNMatrix4 {
        let translation = SCNMatrix4MakeTranslation(0, 0, Float(-distance))
        let rotation = SCNMatrix4MakeRotation(-1 * rotationY, 0, 1, 0)
        let transform = SCNMatrix4Mult(translation, rotation)
        return transform
    }
    
    static func translationMatrix(with matrix: matrix_float4x4, for translation : vector_float4) -> matrix_float4x4 {
        var matrix = matrix
        matrix.columns.3 = translation
        return matrix
    }
    
    static func rotateAroundY(with matrix: matrix_float4x4, for degrees: Float) -> matrix_float4x4 {
        var matrix : matrix_float4x4 = matrix
        matrix.columns.0.x = cos(degrees)
        matrix.columns.0.z = -sin(degrees)
        matrix.columns.2.x = sin(degrees)
        matrix.columns.2.z = cos(degrees)
        return matrix.inverse
    }
    
    static func transformMatrix(for matrix: simd_float4x4, position: vector_float4, degrees: Float) -> simd_float4x4 {
        let bearing = degrees.degreesToRadians
        let translationMatrix = MatrixHelper.translationMatrix(with: matrix_identity_float4x4, for: position)
        let rotationMatrix = MatrixHelper.rotateAroundY(with: matrix_identity_float4x4, for: Float(bearing))
        let transformMatrix = simd_mul(rotationMatrix, translationMatrix)
        return simd_mul(matrix, transformMatrix)
    }
}

extension BinaryInteger {
    
    var degreesToRadians: CGFloat {
        CGFloat(self) * .pi / 180
    }
    
}

extension Double {
    
    var degreesToRadians: Self {
        self * .pi / 180
    }
    
    var radiansToDegrees: Self {
        self * 180 / .pi
    }
}

extension FloatingPoint {
    
    var degreesToRadians: Self {
        self * .pi / 180
    }
    
    var radiansToDegrees: Self {
        self * 180 / .pi
    }
}

extension SCNVector3 {
    
    func distance(to destination: SCNVector3) -> CGFloat {
        let dx = destination.x - x
        let dy = destination.y - y
        let dz = destination.z - z
        return CGFloat(sqrt(dx*dx + dy*dy + dz*dz))
    }
    
    func normalized() -> SCNVector3 {
        let magnitude = ((self.x * self.x) + (self.y * self.y) + (self.z * self.z)).squareRoot()
        return SCNVector3(self.x / magnitude, self.y / magnitude, self.z / magnitude)
    }
    
    enum Axis {
        case x, y, z
        
        func getAxisVector() -> simd_float3 {
            switch self {
            case .x:
                return simd_float3(1,0,0)
            case .y:
                return simd_float3(0,1,0)
            case .z:
                return simd_float3(0,0,1)
            }
        }
    }
    
    func rotatedVector(aroundAxis: Axis, angle: Float) -> SCNVector3 {
        let q = simd_quatf(angle: angle, axis: aroundAxis.getAxisVector())
        let simdVector = q.act(simd_float3(self))
        return SCNVector3(simdVector)
    }
}

extension float4x4 {
    
    public func toMatrix() -> SCNMatrix4 {
        return SCNMatrix4(self)
    }
    
    public var translation4: SCNVector4 {
        get {
            return SCNVector4(columns.3.x, columns.3.y, columns.3.z, columns.3.w)
        }
    }
}

extension SCNNode {
    var width: Float {
        (boundingBox.max.x - boundingBox.min.x) * scale.x
    }
    
    var height: Float {
        (boundingBox.max.y - boundingBox.min.y) * scale.y
    }
    
    func pivotOnTopLeft() {
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation(min.x, (max.y - min.y) + min.y, 0)
    }
    
    func pivotOnTopCenter() {
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2, (max.y - min.y) + min.y, 0)
    }
}

extension SCNVector4 {
    init(_ vector: SIMD4<Float>) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
    }
}

extension SCNMatrix4 {
    public func toSimd() -> float4x4 {
        return float4x4(self)
    }
}


extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
    }
    
    /**
     Factors out the orientation component of the transform.
    */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}
