//
//  TargetingManager.swift
//  ARKitDrone
//
//  Created by Claude on 7/23/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import Foundation
import RealityKit
import simd

@MainActor
class TargetingManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentTargetIndex: Int = 0
    @Published var isAutoTargeting: Bool = true
    
    private weak var helicopterEntity: Entity?
    private var ships: [Ship] = []
    
    // Visual targeting indicators
    private var targetIndicators: [String: ReticleEntity] = [:]
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Setup
    
    func setup(helicopterEntity: Entity?, ships: [Ship]) {
        self.helicopterEntity = helicopterEntity
        self.ships = ships
        
        // Auto-target nearest enemy on setup
        if isAutoTargeting {
            updateAutoTarget()
        }
    }
    
    func updateShips(_ ships: [Ship]) {
        self.ships = ships
        
        // Remove indicators for destroyed ships
        for (shipId, indicator) in targetIndicators {
            if !ships.contains(where: { $0.id == shipId }) {
                indicator.removeFromParent()
                targetIndicators.removeValue(forKey: shipId)
            }
        }
        
        // Update auto-targeting if enabled
        if isAutoTargeting {
            updateAutoTarget()
        }
    }
    
    // MARK: - Auto-Targeting
    
    func updateAutoTarget() {
        guard let helicopterPos = helicopterEntity?.transform.translation else { return }
        
        let availableShips = ships.enumerated().compactMap { (index, ship) -> (Int, Ship, Float)? in
            guard !ship.isDestroyed else { return nil }
            let distance = simd_distance(helicopterPos, ship.entity.transform.translation)
            return (index, ship, distance)
        }
        
        // Find nearest ship
        if let nearestTarget = availableShips.min(by: { $0.2 < $1.2 }) {
            setTarget(index: nearestTarget.0, ship: nearestTarget.1)
        }
    }
    
    // MARK: - Manual Targeting
    
    func switchToNextTarget() {
        let availableShips = ships.enumerated().compactMap { (index, ship) -> Int? in
            guard !ship.isDestroyed else { return nil }
            return index
        }
        
        guard !availableShips.isEmpty else { return }
        
        // Find current target in available ships
        if let currentIndex = availableShips.firstIndex(of: currentTargetIndex) {
            let nextIndex = (currentIndex + 1) % availableShips.count
            let nextTargetIndex = availableShips[nextIndex]
            setTarget(index: nextTargetIndex, ship: ships[nextTargetIndex])
        } else {
            // Current target not available, switch to first available
            let firstTargetIndex = availableShips[0]
            setTarget(index: firstTargetIndex, ship: ships[firstTargetIndex])
        }
        
        // Disable auto-targeting when manually switching
        isAutoTargeting = false
    }
    
    func switchToPreviousTarget() {
        let availableShips = ships.enumerated().compactMap { (index, ship) -> Int? in
            guard !ship.isDestroyed else { return nil }
            return index
        }
        
        guard !availableShips.isEmpty else { return }
        
        // Find current target in available ships
        if let currentIndex = availableShips.firstIndex(of: currentTargetIndex) {
            let prevIndex = currentIndex == 0 ? availableShips.count - 1 : currentIndex - 1
            let prevTargetIndex = availableShips[prevIndex]
            setTarget(index: prevTargetIndex, ship: ships[prevTargetIndex])
        } else {
            // Current target not available, switch to last available
            let lastTargetIndex = availableShips.last!
            setTarget(index: lastTargetIndex, ship: ships[lastTargetIndex])
        }
        
        // Disable auto-targeting when manually switching
        isAutoTargeting = false
    }
    
    func enableAutoTargeting() {
        isAutoTargeting = true
        updateAutoTarget()
    }
    
    // MARK: - Target Management
    
    private func setTarget(index: Int, ship: Ship) {
        // Remove old target indicator
        if currentTargetIndex < ships.count && currentTargetIndex != index {
            let oldShip = ships[currentTargetIndex]
            oldShip.square?.removeFromParent()
            oldShip.square = nil
            oldShip.targetAdded = false
        }
        
        currentTargetIndex = index
        
        // Add new target indicator
        addTargetIndicator(to: ship)
        
        print("🎯 Target switched to ship \(index) at distance: \(getDistanceToCurrentTarget())")
    }
    
    private func addTargetIndicator(to ship: Ship) {
        // Remove existing indicator if any
        ship.square?.removeFromParent()
        
        // Create new reticle
        let square = ReticleEntity()
        ship.square = square
        ship.targetAdded = true
        
        // Position the reticle at the ship's location
        square.transform.translation = ship.entity.transform.translation
        
        // Add to ship's parent (anchor)
        if let parent = ship.entity.parent {
            parent.addChild(square)
        }
        
        // Store in our tracking dictionary
        targetIndicators[ship.id] = square
    }
    
    // MARK: - Helper Methods
    
    func getCurrentTarget() -> Ship? {
        // Filter out destroyed ships first
        let availableShips = ships.filter { !$0.isDestroyed }
        
        guard !availableShips.isEmpty else {
            print("⚠️ No available targets - all ships destroyed")
            return nil
        }
        
        // If current target is invalid, find a new one
        if currentTargetIndex >= ships.count || ships[currentTargetIndex].isDestroyed {
            if isAutoTargeting {
                updateAutoTarget()
            } else {
                // Find first available ship
                for (index, ship) in ships.enumerated() {
                    if !ship.isDestroyed {
                        currentTargetIndex = index
                        break
                    }
                }
            }
        }
        
        guard currentTargetIndex < ships.count && !ships[currentTargetIndex].isDestroyed else {
            print("⚠️ Target validation failed - index: \(currentTargetIndex), ships: \(ships.count)")
            return nil
        }
        
        let target = ships[currentTargetIndex]
        print("🎯 Current target: \(target.id.prefix(8)), destroyed: \(target.isDestroyed)")
        return target
    }
    
    func getDistanceToCurrentTarget() -> Float? {
        guard let helicopterPos = helicopterEntity?.transform.translation,
              let target = getCurrentTarget() else { return nil }
        
        return simd_distance(helicopterPos, target.entity.transform.translation)
    }
    
    func hasValidTarget() -> Bool {
        return getCurrentTarget() != nil
    }
    
    // MARK: - Target Priority
    
    func getTargetPriority(for ship: Ship) -> Float {
        guard let helicopterPos = helicopterEntity?.transform.translation else { return Float.greatestFiniteMagnitude }
        
        let distance = simd_distance(helicopterPos, ship.entity.transform.translation)
        
        // Priority factors (lower score = higher priority)
        var priority = distance
        
        // Prioritize ships that are attacking
        if ship.fired {
            priority *= 0.5 // Higher priority for attacking ships
        }
        
        // Prioritize closer ships
        if distance < 10.0 {
            priority *= 0.7 // Closer ships get priority boost
        }
        
        return priority
    }
    
    func updateTargetIndicators() {
        // Update positions of all target indicators
        for (shipId, indicator) in targetIndicators {
            if let ship = ships.first(where: { $0.id == shipId }) {
                indicator.transform.translation = ship.entity.transform.translation
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        for indicator in targetIndicators.values {
            indicator.removeFromParent()
        }
        targetIndicators.removeAll()
    }
}