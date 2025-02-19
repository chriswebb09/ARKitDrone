/*
 See the LICENSE.txt file for this sample’s licensing information.
 
 Abstract:
 SceneKit node giving the user hints about the status of ARKit world tracking.
 */

import Foundation
import ARKit
import SceneKit

extension FocusSquare {
    
    /*
     The focus square consists of eight segments as follows, which can be individually animated.
     
     s1  s2
     _   _
     s3 |     | s4
     
     s5 |     | s6
     -   -
     s7  s8
     */
    enum Corner {
        case topLeft // s1, s3
        case topRight // s2, s4
        case bottomRight // s6, s8
        case bottomLeft // s5, s7
    }
    
    enum Alignment {
        case horizontal // s1, s2, s7, s8
        case vertical // s3, s4, s5, s6
    }
    
    enum Direction {
        case up, down, left, right
        
        var reversed: Direction {
            switch self {
            case .up:   return .down
            case .down: return .up
            case .left:  return .right
            case .right: return .left
            }
        }
    }
    
    class Segment: SCNNode {
        
        // MARK: - Configuration & Initialization
        
        /// Thickness of the focus square lines in m.
        static let thickness: CGFloat = 0.018
        
        /// Length of the focus square lines in m.
        static let length: CGFloat = 0.5  // segment length
        
        /// Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
        static let openLength: CGFloat = 0.2
        
        let corner: Corner
        let alignment: Alignment
        let plane: SCNPlane
        
        init(name: String, corner: Corner, alignment: Alignment, color: UIColor = FocusSquare.primaryColor, thickness: CGFloat = 0.018) {
            self.corner = corner
            self.alignment = alignment
            switch alignment {
            case .vertical:
                plane = SCNPlane(width: thickness, height: Segment.length)
            case .horizontal:
                plane = SCNPlane(width: Segment.length, height: thickness)
            }
            super.init()
            self.name = name
            let material = plane.firstMaterial!
            material.diffuse.contents = color
            material.isDoubleSided = true
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = color
            geometry = plane
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("\(#function) has not been implemented")
        }
        
        // MARK: - Animating Open/Closed
        
        var openDirection: Direction {
            switch (corner, alignment) {
            case (.topLeft,     .horizontal):   return .left
            case (.topLeft,     .vertical):     return .up
            case (.topRight,    .horizontal):   return .right
            case (.topRight,    .vertical):     return .up
            case (.bottomLeft,  .horizontal):   return .left
            case (.bottomLeft,  .vertical):     return .down
            case (.bottomRight, .horizontal):   return .right
            case (.bottomRight, .vertical):     return .down
            }
        }
        
        func open() {
            if alignment == .horizontal {
                plane.width = Segment.openLength
            } else {
                plane.height = Segment.openLength
            }
            
            let offset = Segment.length / 2 - Segment.openLength / 2
            updatePosition(withOffset: Float(offset), for: openDirection)
        }
        
        func close() {
            let oldLength: CGFloat
            if alignment == .horizontal {
                oldLength = plane.width
                plane.width = Segment.length
            } else {
                oldLength = plane.height
                plane.height = Segment.length
            }
            let offset = Segment.length / 2 - oldLength / 2
            updatePosition(withOffset: Float(offset), for: openDirection.reversed)
        }
        
        private func updatePosition(withOffset offset: Float, for direction: Direction) {
            switch direction {
            case .left:     position.x -= offset
            case .right:    position.x += offset
            case .up:       position.y -= offset
            case .down:     position.y += offset
            }
        }
        
    }
}


/**
 An `SCNNode` which is used to provide uses with visual cues about the status of ARKit world tracking.
 */
class FocusSquare: SCNNode {
    // MARK: - Types
    
    enum State: Equatable {
        case initializing
        case detecting(raycastResult: ARRaycastResult, camera: ARCamera?)
    }
    
    // MARK: - Configuration Properties
    
    // Original size of the focus square in meters.
    static let size: Float = 0.17
    
    // Thickness of the focus square lines in meters.
    static let thickness: Float = 0.018
    
    // Scale factor for the focus square when it is closed, w.r.t. the original size.
    static let scaleForClosedSquare: Float = 0.97
    
    // Side length of the focus square segments when it is open (w.r.t. to a 1x1 square).
    static let sideLengthForOpenSegments: CGFloat = 0.2
    
    // Duration of the open/close animation
    static let animationDuration = 0.7
    
    static let primaryColor = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
    
    // Color of the focus square fill.
    static let fillColor = #colorLiteral(red: 1, green: 0.9254901961, blue: 0.4117647059, alpha: 1)
    
    // MARK: - Properties
    
    /// The most recent position of the focus square based on the current state.
    var lastPosition: SIMD3<Float>? {
        switch state {
        case .initializing: return nil
        case .detecting(let raycastResult, _): return raycastResult.worldTransform.translation
        }
    }
    
    var state: State = .initializing {
        didSet {
            guard state != oldValue else { return }
            
            switch state {
            case .initializing:
                displayAsBillboard()
                
            case let .detecting(raycastResult, camera):
                if let planeAnchor = raycastResult.anchor as? ARPlaneAnchor {
                    displayAsClosed(for: raycastResult, planeAnchor: planeAnchor, camera: camera)
                } else {
                    displayAsOpen(for: raycastResult, camera: camera)
                }
            }
        }
    }
    
    /// Indicates whether the segments of the focus square are disconnected.
    private var isOpen = false
    
    /// Indicates if the square is currently being animated for opening or closing.
    private var isAnimating = false
    
    /// Indicates if the square is currently changing its orientation when the camera is pointing downwards.
    private var isChangingOrientation = false
    
    /// Indicates if the camera is currently pointing towards the floor.
    private var isPointingDownwards = true
    
    /// The focus square's most recent positions.
    private var recentFocusSquarePositions: [SIMD3<Float>] = []
    
    /// Previously visited plane anchors.
    private var anchorsOfVisitedPlanes: Set<ARAnchor> = []
    
    /// List of the segments in the focus square.
    private var segments: [FocusSquare.Segment] = []
    
    /// The primary node that controls the position of other `FocusSquare` nodes.
    private let positioningNode = SCNNode()
    
    /// A counter for managing orientation updates of the focus square.
    private var counterToNextOrientationUpdate: Int = 0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        opacity = 0.0
        
        /*
         The focus square consists of eight segments as follows, which can be individually animated.
         
         s1  s2
         _   _
         s3 |     | s4
         
         s5 |     | s6
         -   -
         s7  s8
         */
        let s1 = Segment(name: "s1", corner: .topLeft, alignment: .horizontal)
        let s2 = Segment(name: "s2", corner: .topRight, alignment: .horizontal)
        let s3 = Segment(name: "s3", corner: .topLeft, alignment: .vertical)
        let s4 = Segment(name: "s4", corner: .topRight, alignment: .vertical)
        let s5 = Segment(name: "s5", corner: .bottomLeft, alignment: .vertical)
        let s6 = Segment(name: "s6", corner: .bottomRight, alignment: .vertical)
        let s7 = Segment(name: "s7", corner: .bottomLeft, alignment: .horizontal)
        let s8 = Segment(name: "s8", corner: .bottomRight, alignment: .horizontal)
        segments = [s1, s2, s3, s4, s5, s6, s7, s8]
        
        let sl: Float = 0.5  // segment length
        let c: Float = FocusSquare.thickness / 2 // correction to align lines perfectly
        s1.simdPosition += [-(sl / 2 - c), -(sl - c), 0]
        s2.simdPosition += [sl / 2 - c, -(sl - c), 0]
        s3.simdPosition += [-sl, -sl / 2, 0]
        s4.simdPosition += [sl, -sl / 2, 0]
        s5.simdPosition += [-sl, sl / 2, 0]
        s6.simdPosition += [sl, sl / 2, 0]
        s7.simdPosition += [-(sl / 2 - c), sl - c, 0]
        s8.simdPosition += [sl / 2 - c, sl - c, 0]
        
        positioningNode.eulerAngles.x = .pi / 2 // Horizontal
        positioningNode.simdScale = [1.0, 1.0, 1.0] * (FocusSquare.size * FocusSquare.scaleForClosedSquare)
        for segment in segments {
            positioningNode.addChildNode(segment)
        }
        positioningNode.addChildNode(fillPlane)
        
        // Always render focus square on top of other content.
        displayNodeHierarchyOnTop(true)
        
        addChildNode(positioningNode)
        
        // Start the focus square as a billboard.
        displayAsBillboard()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: - Appearance
    
    /// Hides the focus square.
    func hide() {
        guard action(forKey: "hide") == nil else { return }
        
        displayNodeHierarchyOnTop(false)
        runAction(.fadeOut(duration: 0.5), forKey: "hide")
    }
    
    /// Unhides the focus square.
    func unhide() {
        guard action(forKey: "unhide") == nil else { return }
        
        displayNodeHierarchyOnTop(true)
        runAction(.fadeIn(duration: 0.5), forKey: "unhide")
    }
    
    /// Displays the focus square parallel to the camera plane.
    private func displayAsBillboard() {
        simdTransform = matrix_identity_float4x4
        eulerAngles.x = .pi / 2
        simdPosition = [0, 0, -0.8]
        unhide()
        performOpenAnimation()
    }
    
    /// Called when a surface has been detected.
    private func displayAsOpen(for raycastResult: ARRaycastResult, camera: ARCamera?) {
        performOpenAnimation()
        setPosition(with: raycastResult, camera)
    }
    
    /// Called when a plane has been detected.
    private func displayAsClosed(for raycastResult: ARRaycastResult, planeAnchor: ARPlaneAnchor, camera: ARCamera?) {
        performCloseAnimation(flash: !anchorsOfVisitedPlanes.contains(planeAnchor))
        anchorsOfVisitedPlanes.insert(planeAnchor)
        setPosition(with: raycastResult, camera)
    }
    
    func setPosition(with raycastResult: ARRaycastResult, _ camera: ARCamera?) {
        let position = raycastResult.worldTransform.translation
        recentFocusSquarePositions.append(position)
        updateTransform(for: raycastResult.worldTransform, camera: camera)
    }
    
    // MARK: Helper Methods
    
    func updateOrientation(basedOn raycastResult: ARRaycastResult) {
        self.simdOrientation = raycastResult.worldTransform.orientation
    }
    //
    func updateOrientation(for transform: simd_float4x4) {
        self.simdOrientation = transform.orientation
    }
    
    func updateOrientation(for transform: SCNMatrix4) {
        self.simdOrientation = transform.toSimdQuatf()
    }
    
    /// Update the transform of the focus square to be aligned with the camera.
    private func updateTransform(for worldTransform: simd_float4x4, camera: ARCamera?) {
        // Average using several most recent positions.
        recentFocusSquarePositions = Array(recentFocusSquarePositions.suffix(10))
        
        // Move to average of recent positions to avoid jitter.
        let average = recentFocusSquarePositions.reduce([0, 0, 0], { $0 + $1 }) / Float(recentFocusSquarePositions.count)
        self.simdPosition = average
        self.simdScale = [1.0, 1.0, 1.0] * scaleBasedOnDistance(camera: camera)
        
        // Correct y rotation when camera is close to horizontal
        // to avoid jitter due to gimbal lock.
        guard let camera = camera else { return }
        let tilt = abs(camera.eulerAngles.x)
        let threshold: Float = .pi / 2 * 0.75
        
        if tilt > threshold {
            if !isChangingOrientation {
                let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
                
                isChangingOrientation = true
                SCNTransaction.begin()
                SCNTransaction.completionBlock = {
                    self.isChangingOrientation = false
                    self.isPointingDownwards = true
                }
                SCNTransaction.animationDuration = isPointingDownwards ? 0.0 : 0.5
                self.simdOrientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
                SCNTransaction.commit()
            }
        } else {
            // Update orientation only twice per second to avoid jitter.
            if counterToNextOrientationUpdate == 30 || isPointingDownwards {
                counterToNextOrientationUpdate = 0
                isPointingDownwards = false
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                updateOrientation(for: worldTransform)
                SCNTransaction.commit()
            }
            
            counterToNextOrientationUpdate += 1
        }
    }
    
    /**
     Reduce visual size change with distance by scaling up when close and down when far away.
     
     These adjustments result in a scale of 1.0x for a distance of 0.7 m or less
     (estimated distance when looking at a table), and a scale of 1.2x
     for a distance 1.5 m distance (estimated distance when looking at the floor).
     */
    private func scaleBasedOnDistance(camera: ARCamera?) -> Float {
        guard let camera = camera else { return 1.0 }
        
        let distanceFromCamera = simd_length(simdWorldPosition - camera.transform.translation)
        if distanceFromCamera < 0.7 {
            return distanceFromCamera / 0.7
        } else {
            return 0.25 * distanceFromCamera + 0.825
        }
    }
    
    // MARK: Animations
    
    private func performOpenAnimation() {
        guard !isOpen, !isAnimating else { return }
        isOpen = true
        isAnimating = true
        
        // Open animation
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
        positioningNode.opacity = 1.0
        for segment in segments {
            segment.open()
        }
        SCNTransaction.completionBlock = {
            self.positioningNode.runAction(pulseAction(), forKey: "pulse")
            // This is a safe operation because `SCNTransaction`'s completion block is called back on the main thread.
            self.isAnimating = false
        }
        SCNTransaction.commit()
        
        // Add a scale/bounce animation.
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
        positioningNode.simdScale = [1.0, 1.0, 1.0] * FocusSquare.size
        SCNTransaction.commit()
    }
    
    private func performCloseAnimation(flash: Bool = false) {
        guard isOpen, !isAnimating else { return }
        isOpen = false
        isAnimating = true
        
        positioningNode.removeAction(forKey: "pulse")
        positioningNode.opacity = 1.0
        
        // Close animation
        SCNTransaction.begin()
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.animationDuration = FocusSquare.animationDuration / 2
        positioningNode.opacity = 0.99
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.animationDuration = FocusSquare.animationDuration / 4
            for segment in self.segments {
                segment.close()
            }
            SCNTransaction.completionBlock = { self.isAnimating = false }
            SCNTransaction.commit()
        }
        SCNTransaction.commit()
        
        // Scale/bounce animation
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.x"), forKey: "transform.scale.x")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.y"), forKey: "transform.scale.y")
        positioningNode.addAnimation(scaleAnimation(for: "transform.scale.z"), forKey: "transform.scale.z")
        
        if flash {
            let waitAction = SCNAction.wait(duration: FocusSquare.animationDuration * 0.75)
            let fadeInAction = SCNAction.fadeOpacity(to: 0.25, duration: FocusSquare.animationDuration * 0.125)
            let fadeOutAction = SCNAction.fadeOpacity(to: 0.0, duration: FocusSquare.animationDuration * 0.125)
            fillPlane.runAction(SCNAction.sequence([waitAction, fadeInAction, fadeOutAction]))
            
            let flashSquareAction = flashAnimation(duration: FocusSquare.animationDuration * 0.25)
            for segment in segments {
                segment.runAction(.sequence([waitAction, flashSquareAction]))
            }
        }
    }
    
    // MARK: Convenience Methods
    
    private func scaleAnimation(for keyPath: String) -> CAKeyframeAnimation {
        let scaleAnimation = CAKeyframeAnimation(keyPath: keyPath)
        
        let easeOut = CAMediaTimingFunction(name: .easeOut)
        let easeInOut = CAMediaTimingFunction(name: .easeInEaseOut)
        let linear = CAMediaTimingFunction(name: .linear)
        
        let size = FocusSquare.size
        let ts = FocusSquare.size * FocusSquare.scaleForClosedSquare
        let values = [size, size * 1.15, size * 1.15, ts * 0.97, ts]
        let keyTimes: [NSNumber] = [0.00, 0.25, 0.50, 0.75, 1.00]
        let timingFunctions = [easeOut, linear, easeOut, easeInOut]
        
        scaleAnimation.values = values
        scaleAnimation.keyTimes = keyTimes
        scaleAnimation.timingFunctions = timingFunctions
        scaleAnimation.duration = FocusSquare.animationDuration
        
        return scaleAnimation
    }
    
    /// Sets the rendering order of the `positioningNode` to show on top or under other scene content.
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
    
    private lazy var fillPlane: SCNNode = {
        let correctionFactor = FocusSquare.thickness / 2 // correction to align lines perfectly
        let length = CGFloat(1.0 - FocusSquare.thickness * 2 + correctionFactor)
        
        let plane = SCNPlane(width: length, height: length)
        let node = SCNNode(geometry: plane)
        node.name = "fillPlane"
        node.opacity = 0.0
        
        let material = plane.firstMaterial!
        material.diffuse.contents = FocusSquare.fillColor
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = FocusSquare.fillColor
        
        return node
    }()
}

// MARK: - Animations and Actions

private func pulseAction() -> SCNAction {
    let pulseOutAction = SCNAction.fadeOpacity(to: 0.4, duration: 0.5)
    let pulseInAction = SCNAction.fadeOpacity(to: 1.0, duration: 0.5)
    pulseOutAction.timingMode = .easeInEaseOut
    pulseInAction.timingMode = .easeInEaseOut
    return SCNAction.repeatForever(SCNAction.sequence([pulseOutAction, pulseInAction]))
}

private func flashAnimation(duration: TimeInterval) -> SCNAction {
    let action = SCNAction.customAction(duration: duration) { (node, elapsedTime) -> Void in
        // animate color from HSB 48/100/100 to 48/30/100 and back
        let elapsedTimePercentage = elapsedTime / CGFloat(duration)
        let saturation = 2.8 * (elapsedTimePercentage - 0.5) * (elapsedTimePercentage - 0.5) + 0.3
        if let material = node.geometry?.firstMaterial {
            material.diffuse.contents = UIColor(hue: 0.1333, saturation: saturation, brightness: 1.0, alpha: 1.0)
        }
    }
    return action
}



// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
     */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
    }
    
    /**
     Factors out the orientation component of the transform.
     */
    var orientation: simd_quatf {
        return simd_quaternion(self)
    }
    
    /**
     Creates a transform matrix with a uniform scale factor in all directions.
     */
    init(uniformScale scale: Float) {
        self = matrix_identity_float4x4
        columns.0.x = scale
        columns.1.y = scale
        columns.2.z = scale
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    /// Extracts the screen space point from a vector returned by SCNView.projectPoint(_:).
    init(_ vector: SCNVector3) {
        self.init(x: CGFloat(vector.x), y: CGFloat(vector.y))
    }
    
    /// Returns the length of a point when considered as a vector. (Used with gesture recognizers.)
    var length: CGFloat {
        return sqrt(x * x + y * y)
    }
}


extension FocusCircle {
    class Segment: SCNNode {
        enum Quadrant {
            case topLeft, topRight, bottomRight, bottomLeft
        }
        
        //        init(name: String, quadrant: Quadrant) {
        //            super.init()
        //
        //            let radius: CGFloat = 0.1
        //            let arcThickness: CGFloat = 0.02
        //            let startAngle: CGFloat
        //            let endAngle: CGFloat
        //            let quadrantOffset: SCNVector3
        //            let rotationAngle: Float
        //
        //            // Define each quadrant covers 90 degrees (π/2 radians)
        //            let arcAngle: CGFloat = .pi * 0.5 // 90 degrees for each quadrant
        //
        //            switch quadrant {
        //            case .topLeft:
        //                startAngle = .pi
        //                endAngle = .pi + arcAngle
        //                quadrantOffset = SCNVector3(-radius, radius, 0) // Position in the top left
        //                rotationAngle = .pi  // Rotate the segment to face top-left
        //            case .topRight:
        //                startAngle = .pi + arcAngle
        //                endAngle = .pi * 2
        //                quadrantOffset = SCNVector3(radius, radius, 0) // Position in the top right
        //                rotationAngle = 0  // No rotation for top-right, it aligns with the positive x-axis
        //            case .bottomRight:
        //                startAngle = 0
        //                endAngle = arcAngle
        //                quadrantOffset = SCNVector3(radius, -radius, 0) // Position in the bottom right
        //                rotationAngle = -.pi / 2 // Rotate the segment to face bottom-right
        //            case .bottomLeft:
        //                startAngle = arcAngle
        //                endAngle = .pi
        //                quadrantOffset = SCNVector3(-radius, -radius, 0) // Position in the bottom left
        //                rotationAngle = .pi / 2 // Rotate the segment to face bottom-left
        //            }
        //
        //            // Define the number of vertices for the arc (higher count will make the arc smoother)
        //            let vertexCount = 30  // Higher count will make the arc smoother
        //            var vertices: [SCNVector3] = []
        //
        //            // Add the points along the outer arc (the visible edge of the arc)
        //            for i in 0..<vertexCount {
        //                let angle = startAngle + CGFloat(i) * (endAngle - startAngle) / CGFloat(vertexCount - 1)
        //                let x = radius * cos(angle)
        //                let y = radius * sin(angle)
        //                vertices.append(SCNVector3(x, y, 0))
        //            }
        //
        //            // Now, create the indices for the geometry (only for the outer arc, no inner lines)
        //            var indices: [Int32] = []
        //
        //            // Connect the outer arc points using triangle strips (no inner center point)
        //            for i in 0..<vertexCount-1 {
        //                indices.append(Int32(i))
        //                indices.append(Int32(i + 1))
        //                indices.append(Int32(i + 1))  // Loop back to the first point for the triangle
        //            }
        //
        //            // Handle the wrapping indices for the last point of the arc
        //            indices.append(Int32(vertexCount - 1))
        //            indices.append(Int32(0)) // Wrap around to start again
        //            indices.append(Int32(0))
        //
        //            // Create the geometry using the vertices and indices
        //            let geometrySource = SCNGeometrySource(vertices: vertices)
        //            let geometryElement = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        //
        //            // Create the final geometry
        //            let geometry = SCNGeometry(sources: [geometrySource], elements: [geometryElement])
        //
        //            // Now create a node for the geometry
        //            let arcNode = SCNNode(geometry: geometry)
        //
        //            // Apply the material to make the arc outline visible
        //            let material = SCNMaterial()
        //            material.diffuse.contents = FocusCircle.primaryColor // Set color or material
        //            material.isDoubleSided = true
        //            arcNode.geometry?.firstMaterial = material
        //
        //            // Apply the correct position and rotation
        //            arcNode.position = quadrantOffset
        //            arcNode.eulerAngles = SCNVector3(0, 0, rotationAngle)
        //
        //            // Ensure that the node is visible in the scene
        //            arcNode.scale = SCNVector3(1, 1, 1)
        //
        //            // Add the arc node to the scene or parent node
        //            self.addChildNode(arcNode)
        //        }
        
        
        
        //        init(name: String, quadrant: Quadrant) {
        //            super.init()
        //
        //            let radius: CGFloat = 0.1
        //            let arcThickness: CGFloat = 0.01
        //            let startAngle: CGFloat
        //            let endAngle: CGFloat
        //            let quadrantOffset: SCNVector3
        //            let rotationAngle: Float
        //
        //            // Define each quadrant covers 90 degrees (π/2 radians)
        //            let arcAngle: CGFloat = .pi * 0.5 // 90 degrees for each quadrant
        //
        //            switch quadrant {
        //            case .topLeft:
        //                startAngle = .pi
        //                endAngle = .pi + arcAngle
        //                quadrantOffset = SCNVector3(-radius, radius, 0) // Position in the top left
        //                rotationAngle = .pi  // Rotate the segment to face top-left
        //            case .topRight:
        //                startAngle = .pi + arcAngle
        //                endAngle = .pi * 2
        //                quadrantOffset = SCNVector3(radius, radius, 0) // Position in the top right
        //                rotationAngle = 0  // No rotation for top-right, it aligns with the positive x-axis
        //            case .bottomRight:
        //                startAngle = 0
        //                endAngle = arcAngle
        //                quadrantOffset = SCNVector3(radius, -radius, 0) // Position in the bottom right
        //                rotationAngle = -.pi / 2 // Rotate the segment to face bottom-right
        //            case .bottomLeft:
        //                startAngle = arcAngle
        //                endAngle = .pi
        //                quadrantOffset = SCNVector3(-radius, -radius, 0) // Position in the bottom left
        //                rotationAngle = .pi / 2 // Rotate the segment to face bottom-left
        //            }
        //
        //            // Define the number of vertices for the arc (higher count will make the arc smoother)
        //            let vertexCount = 30  // Higher count will make the arc smoother
        //            var vertices: [SCNVector3] = []
        //
        //            // Add the points along the outer arc (visible edge of the arc)
        //            for i in 0..<vertexCount {
        //                let angle = startAngle + CGFloat(i) * (endAngle - startAngle) / CGFloat(vertexCount - 1)
        //                let x = radius * cos(angle)
        //                let y = radius * sin(angle)
        //                vertices.append(SCNVector3(x, y, 0))
        //            }
        //
        //            // Define a smaller inner radius for the arc (for the inner edge)
        //            let innerRadius = radius - arcThickness
        //
        //            // Add points for the inner arc (the inner edge of the arc)
        //            for i in 0..<vertexCount {
        //                let angle = startAngle + CGFloat(i) * (endAngle - startAngle) / CGFloat(vertexCount - 1)
        //                let x = innerRadius * cos(angle)
        //                let y = innerRadius * sin(angle)
        //                vertices.append(SCNVector3(x, y, 0))
        //            }
        //
        //            // Now, create the indices for the geometry (triangle strips)
        //            var indices: [Int32] = []
        //
        //            // Connect the vertices for the outer arc to the inner arc to form a thin strip
        //            for i in 0..<vertexCount-1 {
        //                // Outer arc indices
        //                indices.append(Int32(i))
        //                indices.append(Int32(i + 1))
        //                indices.append(Int32(i + vertexCount))
        //
        //                indices.append(Int32(i + vertexCount))
        //                indices.append(Int32(i + 1))
        //                indices.append(Int32(i + vertexCount + 1))
        //            }
        //
        //            // Handle the wrapping indices for the last point of the arc
        //            indices.append(Int32(vertexCount - 1))
        //            indices.append(Int32(0))
        //            indices.append(Int32(2 * vertexCount - 1))
        //
        //            indices.append(Int32(2 * vertexCount - 1))
        //            indices.append(Int32(0))
        //            indices.append(Int32(vertexCount))
        //
        //            // Create the geometry using the vertices and indices
        //            let geometrySource = SCNGeometrySource(vertices: vertices)
        //            let geometryElement = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        //
        //            // Create the final geometry
        //            let geometry = SCNGeometry(sources: [geometrySource], elements: [geometryElement])
        //
        //            // Now create a node for the geometry
        //            let arcNode = SCNNode(geometry: geometry)
        //
        //            // Apply the material to make the arc outline visible
        //            arcNode.geometry?.firstMaterial?.diffuse.contents = FocusCircle.primaryColor // Set color or material
        //            arcNode.geometry?.firstMaterial?.isDoubleSided = true
        //
        //            // Apply the correct position and rotation
        //            arcNode.position = quadrantOffset
        //            arcNode.eulerAngles = SCNVector3(0, 0, rotationAngle)
        //
        //            // Add the arc node to the scene or parent node
        //            self.addChildNode(arcNode)
        //        }
        
        
        init(name: String, quadrant: Quadrant) {
            super.init()
            
            let radius: CGFloat = 0.1
            let arcThickness: CGFloat = 0.01
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
