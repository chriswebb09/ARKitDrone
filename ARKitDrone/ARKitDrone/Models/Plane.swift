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
       private var meshNode: SCNNode!
       private var visible: Bool = false

       init(meshAnchor: ARMeshAnchor) {
           super.init()
           createOcclusionNode(with: meshAnchor)
       }

       required init?(coder: NSCoder) {
           fatalError("init(coder:) has not been implemented")
       }

       func updateOcclusionNode(with meshAnchor: ARMeshAnchor, visible: Bool) {
           self.visible = visible
           let meshGeometry = getGeometry(from: meshAnchor)
           meshNode.removeFromParentNode()
           createMeshNode(with: meshGeometry)
       }

       private func createOcclusionNode(with meshAnchor: ARMeshAnchor) {
           let meshGeometry = getGeometry(from: meshAnchor)
           createMeshNode(with: meshGeometry)
       }

       private func getGeometry(from meshAnchor: ARMeshAnchor) -> SCNGeometry {
           let meshGeometry = SCNGeometry(from: meshAnchor.geometry)
           if visible {
               meshGeometry.materials = [SCNMaterial.visibleMesh]
           } else {
               meshGeometry.materials = [SCNMaterial.occluder]
           }
           return meshGeometry
       }

       private func createMeshNode(with geometry: SCNGeometry) {
           meshNode = SCNNode(geometry: geometry)
           meshNode.renderingOrder = -1
           addChildNode(meshNode)
       }
   }

extension SCNGeometry {

    convenience init(from arGeometry: ARMeshGeometry) {
        let verticesSource = SCNGeometrySource(arGeometry.vertices, semantic: .vertex)
        let normalsSource = SCNGeometrySource(arGeometry.normals, semantic: .normal)
        let faces = SCNGeometryElement(arGeometry.faces)
        self.init(sources: [verticesSource, normalsSource], elements: [faces])
    }

}

//extension SCNGeometrySource {
//
//    convenience init(_ source: ARGeometrySource, semantic: Semantic) {
//        self.init(buffer: source.buffer, vertexFormat: source.format, semantic: semantic, vertexCount: source.count, dataOffset: source.offset, dataStride: source.stride)
//    }
//
//}
//
//extension SCNGeometryElement {
//
//    convenience init(_ source: ARGeometryElement) {
//        let pointer = source.buffer.contents()
//        let byteCount = source.count * source.indexCountPerPrimitive * source.bytesPerIndex
//        let data = Data(bytes: pointer, count: byteCount)
//        self.init(data: data, primitiveType: .of(source.primitiveType), primitiveCount: source.count, bytesPerIndex: source.bytesPerIndex)
//    }
//
//}
//
//extension SCNGeometryPrimitiveType {
//
//    static func of(_ type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
//        switch type {
//        case .line:
//            return .line
//        case .triangle:
//            return .triangles
//        @unknown default:
//            return .line
//        }
//    }
//
//}
//
//class OcclusionNode: SCNNode {
//    
//    static var occlusionMaterial: SCNMaterial {
//        let material = SCNMaterial()
//        material.isDoubleSided = true
//        material.colorBufferWriteMask = []
//        material.writesToDepthBuffer = true
//        material.readsFromDepthBuffer = true
//        return material
//    }
//    
//    init(for anchor: ARMeshAnchor) {
//        super.init()
//        self.name = "occlusion"
//        self.geometry = OcclusionNode.geometry(for: anchor.geometry)
//        self.geometry?.firstMaterial = OcclusionNode.occlusionMaterial
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    public func update(from anchor: ARMeshAnchor) {
//        self.geometry = OcclusionNode.geometry(for: anchor.geometry)
//        self.geometry?.firstMaterial = OcclusionNode.occlusionMaterial
//    }
//    
//    static private func geometry(for mesh: ARMeshGeometry) -> SCNGeometry {
//        let verticesSource = SCNGeometrySource(buffer: mesh.vertices.buffer,
//                                               vertexFormat: mesh.vertices.format,
//                                               semantic: .vertex,
//                                               vertexCount:mesh.vertices.count,
//                                               dataOffset: mesh.vertices.offset,
//                                               dataStride: mesh.vertices.stride)
//        let normalsSource = SCNGeometrySource(buffer: mesh.normals.buffer,
//                                              vertexFormat: mesh.normals.format,
//                                              semantic: .normal,
//                                              vertexCount: mesh.normals.count,
//                                              dataOffset: mesh.normals.offset,
//                                              dataStride: mesh.normals.stride)
//        let vertexCountPerFace = mesh.faces.indexCountPerPrimitive
//        let vertexIndicesPointer = mesh.faces.buffer.contents()
//        var vertexIndices = [UInt32]()
//        vertexIndices.reserveCapacity(vertexCountPerFace)
//        for vertexOffset in 0..<mesh.faces.count * mesh.faces.indexCountPerPrimitive {
//            let vertexIndexPointer = vertexIndicesPointer.advanced(by: vertexOffset * MemoryLayout<UInt32>.size)
//            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
//        }
//        let facesElement = SCNGeometryElement(indices: vertexIndices, primitiveType: .triangles)
//        return SCNGeometry(sources: [verticesSource, normalsSource], elements: [facesElement])
//    }
//}
//
