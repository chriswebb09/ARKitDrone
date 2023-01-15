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
import ARKit

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
