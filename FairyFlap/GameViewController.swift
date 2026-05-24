//
//  GameViewController.swift
//  FairyFlap
//

import UIKit
import SpriteKit

/// Root view controller that hosts the SpriteKit view and presents the
/// initial home scene when the app launches.
class GameViewController: UIViewController {

    private let skView = SKView()
    private var didPresentInitialScene = false

    /// Configures the SpriteKit view and presents `HomeScene` as the first screen.
    override func viewDidLoad() {
        super.viewDidLoad()

        skView.frame = view.bounds
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard !didPresentInitialScene else { return }
        guard skView.bounds.width > 0, skView.bounds.height > 0 else { return }

        let scene = HomeScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)
        didPresentInitialScene = true
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
