//
//  AppDelegate.swift
//  FairyFlap
//
//  Created by Jeff Hedrick on 5/24/2026.
//  Copyright © 2026 Jeff Hedrick. All rights reserved.
//

import UIKit

/// Application entry point. Manages the app lifecycle; game logic lives in
/// the SpriteKit scenes rather than here.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Called once at launch after the app finishes starting up.
    ///
    /// - Parameters:
    ///   - application: The shared application instance.
    ///   - launchOptions: Launch options supplied by the system, if any.
    /// - Returns: `true` to indicate successful launch.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    /// Supplies the scene configuration declared in Info.plist.
    ///
    /// - Parameters:
    ///   - application: The shared application instance.
    ///   - connectingSceneSession: The scene session being created.
    ///   - options: Connection options supplied by the system.
    /// - Returns: The scene configuration that wires up `SceneDelegate`.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    /// Called when the user dismisses a scene session.
    ///
    /// - Parameters:
    ///   - application: The shared application instance.
    ///   - sceneSessions: The discarded scene sessions.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

}
