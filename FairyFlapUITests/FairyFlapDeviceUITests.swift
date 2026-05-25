import XCTest

/// Device-layout smoke tests for small and large iPhone simulators.
///
/// Run via `./scripts/run-ui-tests.sh` on iPhone 16e and iPhone 17 Pro Max.
final class FairyFlapDeviceUITests: FairyFlapUITestCase {

    @MainActor
    func testHomeScreenLoadsOnCurrentDevice() throws {
        assertAppIsRunning()
        XCTAssertTrue(waitForHomeScreen())
    }

    @MainActor
    func testGameplayAndTapsOnCurrentDevice() throws {
        startGame()
        playBriefly(seconds: 3)
        assertAppIsRunning()
    }

    @MainActor
    func testGameOverFlowOnCurrentDevice() throws {
        startGame()
        XCTAssertTrue(waitForGameOverCycle())
        assertAppIsRunning()
    }
}
