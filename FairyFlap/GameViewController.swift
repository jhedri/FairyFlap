//
//  GameViewController.swift
//  FairyFlap
//

import UIKit
import SpriteKit

/// Root view controller that hosts the SpriteKit view and presents the
/// initial home scene when the app launches.
class GameViewController: UIViewController {

    /// Configures the SpriteKit view and presents `HomeScene` as the first screen.
    override func viewDidLoad() {
        super.viewDidLoad()

        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true

        let scene = HomeScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
    }

    /// Allows the game to rotate to any orientation.
    override var shouldAutorotate: Bool {
        return true
    }

    /// Supports portrait and landscape orientations on all sides.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    /// Hides the iOS status bar for a full-screen game experience.
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
