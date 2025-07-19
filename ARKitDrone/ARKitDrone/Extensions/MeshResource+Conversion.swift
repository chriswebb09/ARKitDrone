//
//  MeshResource+Conversion.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import SceneKit
import ARKit
import MetalKit

extension MeshResource {
    
    /// Create MeshResource from SCNGeometry
    static func from(_ scnGeometry: SCNGeometry) throws -> MeshResource {
        // Extract vertices, normals, and indices from SCNGeometry
        guard let geometrySource = scnGeometry.sources(for: .vertex).first,
              let normalSource = scnGeometry.sources(for: .normal).first,
              let element = scnGeometry.elements.first else {
            throw ConversionError.invalidGeometry
        }
        
        // Extract vertex data
        let vertexData = geometrySource.data
        let vertexCount = geometrySource.vectorCount
        let vertexStride = geometrySource.dataStride
        
        // Extract normal data
        let normalData = normalSource.data
        
        // Extract index data
        let indexData = element.data
        
        // Create MeshDescriptor
        var meshDescriptor = MeshDescriptor(name: "ConvertedMesh")
        
        // Set up positions
        var positions: [SIMD3<Float>] = []
        positions.reserveCapacity(vertexCount)
        
        for i in 0..<vertexCount {
            let offset = i * vertexStride
            let x = vertexData.withUnsafeBytes {
                $0.load(
                    fromByteOffset: offset,
                    as: Float.self
                )
            }
            let y = vertexData.withUnsafeBytes {
                $0.load(
                    fromByteOffset: offset + 4,
                    as: Float.self
                )
            }
            let z = vertexData.withUnsafeBytes {
                $0.load(
                    fromByteOffset: offset + 8,
                    as: Float.self
                )
            }
            positions.append(SIMD3<Float>(x, y, z))
        }
        meshDescriptor.positions = MeshBuffers.Positions(positions)
        // Set up normals
        var normals: [SIMD3<Float>] = []
        normals.reserveCapacity(vertexCount)
        
        let normalStride = normalSource.dataStride
        for i in 0..<vertexCount {
            let offset = i * normalStride
            let x = normalData.withUnsafeBytes {
                $0.load(
                    fromByteOffset: offset,
                    as: Float.self
                )
            }
            let y = normalData.withUnsafeBytes {
                $0.load(
                    fromByteOffset: offset + 4,
                    as: Float.self
                )
            }
            let z = normalData.withUnsafeBytes {
                $0.load(
                    fromByteOffset: offset + 8,
                    as: Float.self
                )
            }
            normals.append(SIMD3<Float>(x, y, z))
        }
        meshDescriptor.normals = MeshBuffers.Normals(normals)
        // Set up indices
        var indices: [UInt32] = []
        let indexCount = element.primitiveCount * 3 // Assuming triangles
        indices.reserveCapacity(indexCount)
        
        let bytesPerIndex = element.bytesPerIndex
        for i in 0..<indexCount {
            let offset = i * bytesPerIndex
            if bytesPerIndex == 2 {
                let index = indexData.withUnsafeBytes {
                    $0.load(
                        fromByteOffset: offset,
                        as: UInt16.self
                    )
                }
                indices.append(UInt32(index))
            } else {
                let index = indexData.withUnsafeBytes {
                    $0.load(
                        fromByteOffset: offset,
                        as: UInt32.self
                    )
                }
                indices.append(index)
            }
        }
        meshDescriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [meshDescriptor])
    }
    
    /// Create MeshResource from ARMeshGeometry
    static func from(_ arGeometry: ARMeshGeometry) throws -> MeshResource {
        // Extract vertices
        var positions: [SIMD3<Float>] = []
        positions.reserveCapacity(arGeometry.vertices.count)
        for i in 0..<arGeometry.vertices.count {
            let vertex = arGeometry.vertex(at: UInt32(i))
            positions.append(
                SIMD3<Float>(
                    vertex.0,
                    vertex.1,
                    vertex.2
                )
            )
        }
        // Extract normals
        var normals: [SIMD3<Float>] = []
        normals.reserveCapacity(arGeometry.normals.count)
        for i in 0..<arGeometry.normals.count {
            let normal = arGeometry.normal(at: UInt32(i))
            normals.append(
                SIMD3<Float>(
                    normal.0,
                    normal.1,
                    normal.2
                )
            )
        }
        // Extract indices
        var indices: [UInt32] = []
        for faceIndex in 0..<arGeometry.faces.count {
            let faceIndices = arGeometry.vertexIndicesOf(faceWithIndex: faceIndex)
            indices.append(contentsOf: faceIndices)
        }
        // Create MeshDescriptor
        var meshDescriptor = MeshDescriptor(name: "ARMesh")
        meshDescriptor.positions = MeshBuffers.Positions(positions)
        meshDescriptor.normals = MeshBuffers.Normals(normals)
        meshDescriptor.primitives = .triangles(indices)
        return try MeshResource.generate(from: [meshDescriptor])
    }
    
    /// Create MeshResource from classified ARMeshGeometry
    static func from(_ arGeometry: ARMeshGeometry, ofType type: ARMeshClassification) throws -> MeshResource {
        guard let classification = arGeometry.classification else {
            throw ConversionError.noClassification
        }
        // Filter faces by classification
        let usedFaceIndices = (0..<classification.count).filter { faceIndex in
            return arGeometry.classificationOf(faceWithIndex: faceIndex) == type
        }
        let usedIndices = usedFaceIndices.flatMap { faceIndex in
            return arGeometry.vertexIndicesOf(faceWithIndex: faceIndex)
        }
        let usedVertexIndices = Set<UInt32>(usedIndices)
        // Extract classified vertices and normals
        let positions = usedVertexIndices.map { vertexIndex in
            let vertex = arGeometry.vertex(at: vertexIndex)
            return SIMD3<Float>(
                vertex.0,
                vertex.1,
                vertex.2
            )
        }
        let normals = usedVertexIndices.map { vertexIndex in
            let normal = arGeometry.normal(at: vertexIndex)
            return SIMD3<Float>(
                normal.0,
                normal.1,
                normal.2
            )
        }
        // Create vertex index mapping
        let vertexIndexMap = Dictionary(uniqueKeysWithValues: usedVertexIndices.enumerated().map { ($1, UInt32($0)) })
        let remappedIndices = usedIndices.compactMap { vertexIndexMap[$0] }
        // Generate texture coordinates
        let bounds = positions.reduce((SIMD3<Float>(repeating: Float.greatestFiniteMagnitude),
                                       SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude))) { (bbox, vertex) in
            return (min(bbox.0, vertex), max(bbox.1, vertex))
        }
        let size = bounds.1 - bounds.0
        let texCoords = positions.map { vertex in
            SIMD2<Float>((vertex.x - bounds.0.x) / size.x, (vertex.z - bounds.0.z) / size.z)
        }
        // Create MeshDescriptor
        var meshDescriptor = MeshDescriptor(name: "ClassifiedARMesh")
        meshDescriptor.positions = MeshBuffers.Positions(positions)
        meshDescriptor.normals = MeshBuffers.Normals(normals)
        meshDescriptor.textureCoordinates = MeshBuffers.TextureCoordinates(texCoords)
        meshDescriptor.primitives = .triangles(remappedIndices)
        return try MeshResource.generate(from: [meshDescriptor])
    }
    // Note: Use RealityKit's built-in MeshResource.generateBox, generateSphere, etc. methods directly
    // No need to wrap them since they're already available
}

// MARK: - Conversion Errors

enum ConversionError: Error {
    case invalidGeometry
    case noClassification
    case unsupportedFormat
    case missingData
    
    var localizedDescription: String {
        switch self {
        case .invalidGeometry:
            return "Invalid or incomplete geometry data"
        case .noClassification:
            return "ARMeshGeometry has no classification data"
        case .unsupportedFormat:
            return "Unsupported geometry format"
        case .missingData:
            return "Required geometry data is missing"
        }
    }
}
