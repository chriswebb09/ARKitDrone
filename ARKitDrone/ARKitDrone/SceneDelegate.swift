//
//  SceneDelegate..swift
//  ARKitDrone
//
//  Created by Christopher Webb on 7/18/25.
//  Copyright © 2025 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MenuViewController()
        window?.makeKeyAndVisible()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Preload models as early as possible
        Task {
            // Preload USDZ models
            await AsyncModelLoader.shared.preloadModels([
                "F-35B_Lightning_II",
                "m1tankmodel"
            ])
            // Preload Reality files separately
            do {
                _ = try await AsyncModelLoader.shared.loadRealityModel(named: "heli")
                print("🚀 All models preloaded!")
            } catch {
                print("❌ Failed to preload Reality model: \(error)")
            }
        }
    }
    
    // Add other scene lifecycle methods as needed
}
