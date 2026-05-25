//
//  SceneDelegate.swift
//  FairyFlap
//

import UIKit

/// Manages the app's window scene lifecycle for iOS 13 and later.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// The app's primary window, created when the scene connects.
    var window: UIWindow?

    /// Creates the app window and loads the main storyboard's root view controller.
    ///
    /// - Parameters:
    ///   - scene: The scene session being connected.
    ///   - session: Metadata for the new scene session.
    ///   - connectionOptions: Additional connection options from the system.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        self.window = window
        window.makeKeyAndVisible()
    }

}
