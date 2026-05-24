//
//  AppDelegate.swift
//  FairyFlap
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import UIKit

/// Application entry point. Manages the app lifecycle; game logic lives in
/// the SpriteKit scenes rather than here.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Called once at launch after the app finishes starting up.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    /// Supplies the scene configuration declared in Info.plist.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Called when the user dismisses a scene session.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

}
