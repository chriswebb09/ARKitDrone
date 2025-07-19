//
//  Material+RealityKit.swift
//  ARKitDrone
//
//  Created by Claude on 7/13/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import RealityKit
import UIKit

// MARK: - RealityKit Material Extensions

extension SimpleMaterial {
    
    /// Create SimpleMaterial with basic properties
    static func create(color: UIColor, metallic: Float = 0.0, roughness: Float = 1.0) -> SimpleMaterial {
        var material = SimpleMaterial()
        material.color = .init(tint: color)
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)
        return material
    }
    
    /// Create material from texture image
    @MainActor
    static func create(from image: UIImage, metallic: Float = 0.0, roughness: Float = 1.0) -> SimpleMaterial? {
        guard let cgImage = image.cgImage,
              let texture = try? TextureResource(
                image: cgImage,
                withName: nil,
                options: TextureResource.CreateOptions(semantic: .color)
              ) else {
            return nil
        }
        var material = SimpleMaterial()
        material.color = .init(texture: .init(texture))
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)
        return material
    }
    
    /// Create material from texture name
    @MainActor
    static func create(fromTexture textureName: String, metallic: Float = 0.0,  roughness: Float = 1.0) -> SimpleMaterial? {
        guard let texture = try? TextureResource.load(named: textureName) else {
            return nil
        }
        var material = SimpleMaterial()
        material.color = .init(texture: .init(texture))
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)
        return material
    }
}


extension UnlitMaterial {
    
    /// Create UnlitMaterial from color
    static func create(color: UIColor) -> UnlitMaterial {
        var material = UnlitMaterial()
        material.color = .init(tint: color)
        return material
    }
    
    /// Create UnlitMaterial from texture
    @MainActor
    static func create(from image: UIImage) -> UnlitMaterial? {
        guard let cgImage = image.cgImage,
              let texture = try? TextureResource(
                image: cgImage,
                withName: nil,
                options: TextureResource.CreateOptions(semantic: .color)
              ) else {
            return nil
        }
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        return material
    }
    
    /// Create UnlitMaterial from texture name
    @MainActor
    static func create(fromTexture textureName: String) -> UnlitMaterial? {
        guard let texture = try? TextureResource.load(named: textureName) else {
            return nil
        }
        
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        return material
    }
}


extension PhysicallyBasedMaterial {
    
    /// Create PBR material with full control
    static func create(baseColor: UIColor = .white, metallic: Float = 0.0, roughness: Float = 0.5, specular: Float = 0.5) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: baseColor)
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)
        material.specular = .init(floatLiteral: specular)
        return material
    }
    
    /// Create PBR material from texture
    @MainActor
    static func create(baseColorTexture: UIImage, metallic: Float = 0.0, roughness: Float = 0.5) -> PhysicallyBasedMaterial? {
        guard let cgImage = baseColorTexture.cgImage,
              let texture = try? TextureResource(
                image: cgImage,
                withName: nil,
                options: TextureResource.CreateOptions(semantic: .color)
              ) else {
            return nil
        }
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)
        return material
    }
    
    /// Create PBR material from texture name
    @MainActor
    static func create(baseColorTexture textureName: String, metallic: Float = 0.0, roughness: Float = 0.5) -> PhysicallyBasedMaterial? {
        guard let texture = try? TextureResource.load(named: textureName) else {
            return nil
        }
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(texture: .init(texture))
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)
        return material
    }
}

// MARK: - Material Utility Functions

extension Material {
    
    /// Create a basic colored material
    static func colored(_ color: UIColor) -> SimpleMaterial {
        return SimpleMaterial.create(color: color)
    }
    
    /// Create a metallic material
    static func metallic(_ color: UIColor, roughness: Float = 0.1) -> SimpleMaterial {
        return SimpleMaterial.create(color: color, metallic: 1.0, roughness: roughness)
    }
    
    /// Create a matte material
    static func matte(_ color: UIColor) -> SimpleMaterial {
        return SimpleMaterial.create(color: color, metallic: 0.0, roughness: 1.0)
    }
    
    /// Create an emissive material (using UnlitMaterial for glow effect)
    static func emissive(_ color: UIColor) -> UnlitMaterial {
        return UnlitMaterial.create(color: color)
    }
}
