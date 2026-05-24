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
                            
    var window: UIWindow?

    /// Called once at launch after the app finishes starting up.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    /// Called when the app is interrupted (e.g. phone call, home button).
    /// Use this to pause gameplay if needed.
    func applicationWillResignActive(_ application: UIApplication) {
    }

    /// Called when the app moves to the background. Use this to save state.
    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    /// Called when the app returns from the background to the foreground.
    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    /// Called when the app becomes active again after being inactive.
    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    /// Called just before the app is terminated. Use this for final cleanup.
    func applicationWillTerminate(_ application: UIApplication) {
    }

}