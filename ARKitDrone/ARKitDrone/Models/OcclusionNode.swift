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

// MARK: - Occlusion Entity

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
        // Set rendering order
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


