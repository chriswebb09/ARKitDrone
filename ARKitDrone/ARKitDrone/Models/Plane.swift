//
//  Plane.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 10/11/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import ARKit

class OcclusionNode: SCNNode {
    
    static var occlusionMaterial: SCNMaterial {
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.colorBufferWriteMask = []
        material.writesToDepthBuffer = true
        material.readsFromDepthBuffer = true
        return material
    }
    
    init(for anchor: ARMeshAnchor) {
        super.init()
        self.name = "occlusion"
        self.geometry = OcclusionNode.geometry(for: anchor.geometry)
        self.geometry?.firstMaterial = OcclusionNode.occlusionMaterial
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func update(from anchor: ARMeshAnchor) {
        self.geometry = OcclusionNode.geometry(for: anchor.geometry)
        self.geometry?.firstMaterial = OcclusionNode.occlusionMaterial
    }
    
    static private func geometry(for mesh: ARMeshGeometry) -> SCNGeometry {
        let verticesSource = SCNGeometrySource(buffer: mesh.vertices.buffer,
                                               vertexFormat: mesh.vertices.format,
                                               semantic: .vertex,
                                               vertexCount:mesh.vertices.count,
                                               dataOffset: mesh.vertices.offset,
                                               dataStride: mesh.vertices.stride)
        let normalsSource = SCNGeometrySource(buffer: mesh.normals.buffer,
                                              vertexFormat: mesh.normals.format,
                                              semantic: .normal,
                                              vertexCount: mesh.normals.count,
                                              dataOffset: mesh.normals.offset,
                                              dataStride: mesh.normals.stride)
        let vertexCountPerFace = mesh.faces.indexCountPerPrimitive
        let vertexIndicesPointer = mesh.faces.buffer.contents()
        var vertexIndices = [UInt32]()
        vertexIndices.reserveCapacity(vertexCountPerFace)
        for vertexOffset in 0..<mesh.faces.count * mesh.faces.indexCountPerPrimitive {
            let vertexIndexPointer = vertexIndicesPointer.advanced(by: vertexOffset * MemoryLayout<UInt32>.size)
            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
        }
        let facesElement = SCNGeometryElement(indices: vertexIndices, primitiveType: .triangles)
        return SCNGeometry(sources: [verticesSource, normalsSource], elements: [facesElement])
    }
}

