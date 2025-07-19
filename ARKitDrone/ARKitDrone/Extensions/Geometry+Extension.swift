//
//  SCNGeometry+Extension.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/30/24.
//  Copyright © 2024 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit
import ARKit

extension SCNGeometryElement {
    convenience init(_ source: ARGeometryElement) {
        let pointer = source.buffer.contents()
        let byteCount = source.count * source.indexCountPerPrimitive * source.bytesPerIndex
        let data = Data(
            bytesNoCopy: pointer,
            count: byteCount,
            deallocator: .none
        )
        self.init(
            data: data,
            primitiveType: .of(source.primitiveType),
            primitiveCount: source.count,
            bytesPerIndex: source.bytesPerIndex
        )
    }
}

extension SCNGeometryPrimitiveType {
    static func of(_ type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
        switch type {
        case .line:
            return .line
        case .triangle:
            return .triangles
        @unknown default:
            return .point
        }
    }
}


extension ARMeshGeometry {
    /// To get the mesh's classification, the sample app parses the classification's raw data and instantiates an
    /// `ARMeshClassification` object. For efficiency, ARKit stores classifications in a Metal buffer in `ARMeshGeometry`.
    func classificationOf(faceWithIndex index: Int) -> ARMeshClassification {
        guard let classification = classification else { return .none }
        assert(classification.format == MTLVertexFormat.uchar, "Expected one unsigned char (one byte) per classification")
        let classificationPointer = classification.buffer.contents().advanced(by: classification.offset + (classification.stride * index))
        let classificationValue = Int(classificationPointer.assumingMemoryBound(to: CUnsignedChar.self).pointee)
        return ARMeshClassification(rawValue: classificationValue) ?? .none
    }
    
    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
        let vertexCountPerFace = faces.indexCountPerPrimitive
        let vertexIndicesPointer = faces.buffer.contents()
        var vertexIndices = [UInt32]()
        vertexIndices.reserveCapacity(vertexCountPerFace)
        for vertexOffset in 0..<vertexCountPerFace {
            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
        }
        return vertexIndices
    }
    
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(
            by: vertices.offset + (vertices.stride * Int(index))
        )
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }
    
    func normal(at index: UInt32) -> (Float, Float, Float) {
        assert(normals.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
        let normal = normalPointer.assumingMemoryBound(
            to: (
                Float,
                Float,
                Float
            ).self
        ).pointee
        return normal
    }
}


extension SCNGeometrySource {
    convenience init(_ source: ARGeometrySource, semantic: Semantic) {
        self.init(
            buffer: source.buffer,
            vertexFormat: source.format,
            semantic: semantic,
            vertexCount: source.count,
            dataOffset: source.offset,
            dataStride: source.stride
        )
    }
}

extension SCNGeometry {
    convenience init(arGeometry: ARMeshGeometry) {
        let verticesSource = SCNGeometrySource(
            arGeometry.vertices,
            semantic: .vertex
        )
        let normalsSource = SCNGeometrySource(
            arGeometry.normals,
            semantic: .normal
        )
        let faces = SCNGeometryElement(arGeometry.faces)
        self.init(
            sources: [verticesSource, normalsSource],
            elements: [faces]
        )
    }
    
    static func from(_ arGeometry: ARMeshGeometry, ofType type: ARMeshClassification) -> SCNGeometry? {
        guard let classification = arGeometry.classification else {
            return nil  // No classification is available
        }
        guard classification.format == MTLVertexFormat.uchar else {
            return nil
        }
        // Collect all face & vertex indicies, that belong to the given `type`
        let usedFaceIndices = (0..<classification.count).filter { faceIndex in
            return arGeometry.classificationOf(
                faceWithIndex: faceIndex
            ) == type
        }
        let usedIndicies = usedFaceIndices.flatMap { faceIndex in
            return arGeometry.vertexIndicesOf(
                faceWithIndex: faceIndex
            )
        }
        let usedVertexIndices = Set<UInt32>(usedIndicies)
        // Generate geometry sources
        let vertices = usedVertexIndices.map { (vertexIndex: UInt32) -> SCNVector3 in
            let (x, y, z) = arGeometry.vertex(
                at: vertexIndex
            )
            return SCNVector3(
                x: x,
                y: y,
                z: z
            )
        }
        let normals = usedVertexIndices.map { (vertexIndex) -> SCNVector3 in
            let (x, y, z) = arGeometry.normal(
                at: UInt32(vertexIndex)
            )
            return SCNVector3(
                x: x,
                y: y,
                z: z
            )
        }
        // Texture coords (image paste technic)
        let bounds = vertices.reduce((SCNVector3Zero, SCNVector3Zero)) { (bbox, vertex) -> (SCNVector3, SCNVector3) in
            return (
                SCNVector3(
                    x: .minimum(bbox.0.x, vertex.x),
                    y:  .minimum(bbox.0.y, vertex.y),
                    z: .minimum(bbox.0.z, vertex.z)
                ),
                SCNVector3(
                    x: .maximum(bbox.1.x, vertex.x),
                    y: .maximum(bbox.1.y, vertex.y),
                    z: .maximum(bbox.1.z, vertex.z)
                )
            )
        }
        let size = SCNVector3Make(
            bounds.1.x - bounds.0.x,
            bounds.1.y - bounds.0.y,
            bounds.1.z - bounds.0.z
        )
        let texcoords = vertices.map { vertex -> CGPoint in
            return CGPoint(
                x: CGFloat((vertex.x - bounds.0.x) / size.x),
                y: CGFloat((vertex.z - bounds.0.z) / size.z)
            )
        }
        let verticesSource = SCNGeometrySource(vertices: vertices)
        let normalsSource = SCNGeometrySource(normals: normals)
        let faces = SCNGeometryElement(
            indices: usedIndicies,
            primitiveType: .triangles
        )
        let texcoordsSource = SCNGeometrySource(textureCoordinates: texcoords)
        return SCNGeometry(
            sources: [
                verticesSource,
                normalsSource,
                texcoordsSource
            ],
            elements: [faces]
        )
    }
    
    static func normalForest(from arGeometry: ARMeshGeometry) -> SCNGeometry {
        let vertices = (0..<arGeometry.vertices.count).map { (vertexIdx: Int) -> SCNVector3 in
            let (x, y, z) = arGeometry.vertex(
                at: UInt32(vertexIdx)
            )
            return SCNVector3(
                x: x,
                y: y,
                z: z
            )
        }
        let normalVertices = (0..<arGeometry.normals.count).map { (normalIdx: Int) -> SCNVector3 in
            let (x, y, z) = arGeometry.normal(
                at: UInt32(normalIdx)
            )
            let startVertex = vertices[normalIdx]
            let normalVector = SCNVector3(
                x: x,
                y: y,
                z: z
            ).rescaled(to: 0.04) // 4 cm
            return SCNVector3(
                x: startVertex.x + normalVector.x,
                y: startVertex.y + normalVector.y,
                z: startVertex.z + normalVector.z
            )
        }
        let vertexSource = SCNGeometrySource(vertices: vertices + normalVertices)
        let linesSource = SCNGeometryElement(
            indices: (0..<vertices.count).flatMap { [UInt32($0), UInt32($0 + vertices.count)] },
            primitiveType: .line
        )
        let forest = SCNGeometry(
            sources: [vertexSource],
            elements: [linesSource]
        )
        return forest
    }
}

extension SCNGeometry {
    
    convenience init(from arGeometry: ARMeshGeometry) {
        let verticesSource = SCNGeometrySource(
            arGeometry.vertices,
            semantic: .vertex
        )
        let normalsSource = SCNGeometrySource(
            arGeometry.normals,
            semantic: .normal
        )
        let faces = SCNGeometryElement(arGeometry.faces)
        self.init(
            sources: [
                verticesSource,
                normalsSource
            ],
            elements: [faces]
        )
    }
}
