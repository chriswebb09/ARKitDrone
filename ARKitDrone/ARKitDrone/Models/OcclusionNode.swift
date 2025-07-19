//
//  OcclusionNode.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 10/11/23.
//  Copyright © 2023 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import ARKit
import RealityKit

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
        meshGeometry.materials = visible ? [SCNMaterial.visibleMesh] : [SCNMaterial.occluder]
        return meshGeometry
    }
    
    private func createMeshNode(with geometry: SCNGeometry) {
        meshNode = SCNNode(geometry: geometry)
        meshNode.renderingOrder = -1
        addChildNode(meshNode)
    }
}

// MARK: - RealityKit Occlusion Entity

class OcclusionEntity: Entity {
    
    private var meshEntity: Entity?
    private var visible: Bool = false
    
    init(meshAnchor: ARMeshAnchor) {
        super.init()
        createOcclusionEntity(with: meshAnchor)
    }
    
    required init() {
        super.init()
    }
    
    func updateOcclusionEntity(with meshAnchor: ARMeshAnchor, visible: Bool) {
        self.visible = visible
        // Remove existing mesh entity
        meshEntity?.removeFromParent()
        // Create new mesh entity with updated geometry
        do {
            let meshResource = try MeshResource.from(meshAnchor.geometry)
            createMeshEntity(with: meshResource)
        } catch {
            print("Failed to create mesh resource from AR mesh: \(error)")
        }
    }
    
    private func createOcclusionEntity(with meshAnchor: ARMeshAnchor) {
        do {
            let meshResource = try MeshResource.from(meshAnchor.geometry)
            createMeshEntity(with: meshResource)
        } catch {
            print("Failed to create mesh resource from AR mesh: \(error)")
        }
    }
    
    private func createMeshEntity(with meshResource: MeshResource) {
        let entity = Entity()
        // Create appropriate material based on visibility
        let material = visible ? createVisibleMeshMaterial() : createOccluderMaterial()
        // Set up model component
        entity.components.set(
            ModelComponent(
                mesh: meshResource,
                materials: [material]
            )
        )
        // Set rendering order (RealityKit doesn't have direct renderingOrder, but we can use other approaches)
        entity.name = visible ? "visibleMesh" : "occluder"
        meshEntity = entity
        addChild(entity)
    }
    
    private func createVisibleMeshMaterial() -> Material {
        // Create a visible material for debugging/visualization
        var material = SimpleMaterial()
        material.color = .init(tint: UIColor.white.withAlphaComponent(0.5))
        material.roughness = .float(1.0)
        material.metallic = .float(0.0)
        return material
    }
    
    private func createOccluderMaterial() -> Material {
        // Create an occlusion material (invisible but blocks rendering)
        let material = OcclusionMaterial()
        return material
    }
}


