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

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = MenuViewController()
//         Replace with your VC
        window?.makeKeyAndVisible()
    }

    // Add other scene lifecycle methods as needed
}
