import XCTest

/// Core UI smoke tests for Fairy Flap.
///
/// Run on multiple simulators for App Store-style device coverage:
///   ./scripts/run-ui-tests.sh
final class FairyFlapUITests: FairyFlapUITestCase {

    // MARK: - 1. Launch

    @MainActor
    func testAppLaunchesSuccessfully() throws {
        assertAppIsRunning()
        XCTAssertTrue(waitForHomeScreen())
    }

    // MARK: - 2. Game scene loads

    @MainActor
    func testMainGameSceneLoadsWithoutCrashing() throws {
        startGame()
        assertAppIsRunning()
    }

    // MARK: - 3. Tap starts gameplay

    @MainActor
    func testTapStartsGameplay() throws {
        XCTAssertTrue(waitForHomeScreen())
        tapCenter()
        sleep(1)
        assertAppIsRunning()
    }

    // MARK: - 4. Multiple taps do not crash

    @MainActor
    func testMultipleTapsDoNotCrash() throws {
        startGame()
        for _ in 0..<6 {
            tapGameplayArea()
        }
        assertAppIsRunning()
    }

    // MARK: - 5. Sustained gameplay

    @MainActor
    func testGameRunsForSeveralSecondsWithoutCrashing() throws {
        startGame()
        playBriefly(seconds: 5)
        assertAppIsRunning()
    }

    // MARK: - 6. Game over / restart

    @MainActor
    func testGameOverReturnsWithoutCrashing() throws {
        startGame()
        XCTAssertTrue(
            waitForGameOverCycle(),
            "App should survive the game-over return-home flow"
        )
        assertAppIsRunning()
    }

    @MainActor
    func testRestartAfterGameOverStartsNewRun() throws {
        startGame()
        XCTAssertTrue(waitForGameOverCycle())
        tapCenter()
        sleep(1)
        playBriefly(seconds: 2)
        assertAppIsRunning()
    }

    // MARK: - 7. Portrait orientation

    @MainActor
    func testPortraitOrientationRemainsStable() throws {
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(waitForHomeScreen())
        assertAppIsRunning()
    }

    // MARK: - Stability

    @MainActor
    func testRelaunchAfterGameplayShowsHomeScreen() throws {
        startGame()
        playBriefly(seconds: 2)
        app.terminate()
        app.launch()
        XCTAssertTrue(waitForHomeScreen())
        assertAppIsRunning()
    }
}
