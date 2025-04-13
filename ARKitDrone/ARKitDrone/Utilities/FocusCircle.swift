//
//  FocusCircle.swift
//  ARKitDrone
//
//  Created by Christopher Webb on 3/7/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import SceneKit


class FocusCircle: SCNNode {
    static let primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
    
    private var segments: [FocusCircle.Segment] = []
    private let positioningNode = SCNNode()
    
    override init() {
        super.init()
        //        opacity = 0.0
        
        let s1 = Segment(name: "s1", quadrant: .topLeft)
        let s2 = Segment(name: "s2", quadrant: .topRight)
        let s3 = Segment(name: "s3", quadrant: .bottomRight)
        let s4 = Segment(name: "s4", quadrant: .bottomLeft)
        
        segments = [s1, s2, s3, s4]
        
        for segment in segments {
            positioningNode.addChildNode(segment)
        }
        addChildNode(positioningNode)
        displayAsBillboard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    private func displayAsBillboard() {
        simdTransform = matrix_identity_float4x4
        eulerAngles.x = .pi / 2
        simdPosition = [0, 0, -0.8]
        unhide()
        //        performOpenAnimation()
    }
    
    func unhide() {
        guard action(forKey: "unhide") == nil else { return }
        
        displayNodeHierarchyOnTop(true)
        runAction(.fadeIn(duration: 0.5), forKey: "unhide")
    }
    
    func displayNodeHierarchyOnTop(_ isOnTop: Bool) {
        // Recursivley traverses the node's children to update the rendering order depending on the `isOnTop` parameter.
        func updateRenderOrder(for node: SCNNode) {
            node.renderingOrder = isOnTop ? 2 : 0
            
            for material in node.geometry?.materials ?? [] {
                material.readsFromDepthBuffer = !isOnTop
            }
            
            for child in node.childNodes {
                updateRenderOrder(for: child)
            }
        }
        
        updateRenderOrder(for: positioningNode)
    }
}



extension FocusCircle {
    class Segment: SCNNode {
        enum Quadrant {
            case topLeft, topRight, bottomRight, bottomLeft
        }
        
        init(name: String, quadrant: Quadrant) {
            super.init()
            
            let radius: CGFloat = 0.1
//            let arcThickness: CGFloat = 0.01
            let startAngle: CGFloat
            let endAngle: CGFloat
            let quadrantOffset: SCNVector3
            let rotationAngle: Float
            
            // Each segment will have a 90-degree arc, divided into four parts.
            let arcAngle: CGFloat = .pi * 0.5 // 90 degrees for each quadrant
            
            switch quadrant {
            case .topLeft:
                startAngle = .pi
                endAngle = .pi + arcAngle
                quadrantOffset = SCNVector3(radius, radius, 0) // Position in the top left
                rotationAngle = .pi  // Rotate the segment to face top-left
            case .topRight:
                startAngle = .pi + arcAngle
                endAngle = .pi * 2
                quadrantOffset = SCNVector3(radius, radius, 0) // Position in the top right
                rotationAngle = -.pi  // No rotation for top-right, it aligns with the positive x-axis
            case .bottomRight:
                startAngle = 0
                endAngle = arcAngle
                quadrantOffset = SCNVector3(radius, radius, 0) // Position in the bottom right
                rotationAngle = -.pi / 2 // Rotate the segment to face bottom-right
            case .bottomLeft:
                startAngle = arcAngle
                endAngle = .pi
                quadrantOffset = SCNVector3(radius, radius, 0) // Position in the bottom left
                rotationAngle = .pi / 2 // Rotate the segment to face bottom-left
            }
            
            // Create the vertices for the arc (triangle fan)
            let vertexCount = 8  // Number of vertices for the arc (higher means smoother)
            var vertices: [SCNVector3] = []
            
            // Add the center point (all arcs share the center)
            vertices.append(SCNVector3(0, 0, 0))
            
            // Create points along the arc for the outer edge
            for i in 0..<vertexCount {
                let angle = startAngle + CGFloat(i) * (endAngle - startAngle) / CGFloat(vertexCount - 1)
                let x = radius * cos(angle)
                let y = radius * sin(angle)
                vertices.append(SCNVector3(x, y, 0))
            }
            
            // Now, create the indices for the geometry (triangle fan indices)
            var indices: [Int32] = []
            for i in 1..<vertexCount {
                indices.append(0)  // The center vertex
                indices.append(Int32(i))  // Current outer vertex
                indices.append(Int32(i + 1 == vertexCount ? 1 : i + 1))  // Next outer vertex (loop around)
            }
            
            // Create the geometry using the vertices and indices
            let geometrySource = SCNGeometrySource(vertices: vertices)
            let geometryElement = SCNGeometryElement(indices: indices, primitiveType: .line)
            
            // Create the final geometry
            let geometry = SCNGeometry(sources: [geometrySource], elements: [geometryElement])
            
            // Now create a node for the geometry
            let arcNode = SCNNode(geometry: geometry)
            
            let material =  arcNode.geometry!.firstMaterial!
            material.diffuse.contents = TargetNode.fillColor
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = TargetNode.fillColor
            
            // Apply the correct position and rotation
            arcNode.position = quadrantOffset
            arcNode.eulerAngles = SCNVector3(0, 0, rotationAngle)
            
            // Ensure that the node is visible in the scene
            arcNode.scale = SCNVector3(1, 1, 1)
            
            // Add the arc node to the scene or parent node
            self.addChildNode(arcNode)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("\(#function) has not been implemented")
        }
    }
}
