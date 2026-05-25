import XCTest

/// Shared setup and helpers for Fairy Flap UI tests.
///
/// SpriteKit nodes are not reliably exposed to XCUITest, so gameplay is exercised
/// through normalized coordinate taps and foreground-state checks.
class FairyFlapUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        XCUIDevice.shared.orientation = .portrait
        app.launch()
    }

    // MARK: - Actions

    /// Waits for the app to reach the foreground and the home scene to finish loading.
    @discardableResult
    func waitForHomeScreen(timeout: TimeInterval = 8) -> Bool {
        guard app.wait(for: .runningForeground, timeout: timeout) else { return false }
        sleep(1)
        return app.state == .runningForeground
    }

    /// Taps the screen to start gameplay from the home scene.
    func startGame() {
        XCTAssertTrue(waitForHomeScreen(), "App did not reach the home screen")
        tapCenter()
        sleep(1)
        assertAppIsRunning()
    }

    func tapCenter() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func tapGameplayArea() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
    }

    /// Plays briefly with intermittent taps.
    func playBriefly(seconds: UInt32 = 3) {
        let end = Date().addingTimeInterval(TimeInterval(seconds))
        while Date() < end {
            tapGameplayArea()
            sleep(1)
        }
    }

    /// Lets the fairy fall without input until game over and return home.
    @discardableResult
    func waitForGameOverCycle(timeout: TimeInterval = 18) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.state != .runningForeground { return false }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        }
        return app.state == .runningForeground
    }

    func assertAppIsRunning() {
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3))
    }
}
