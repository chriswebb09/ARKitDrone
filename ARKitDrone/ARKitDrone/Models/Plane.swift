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
