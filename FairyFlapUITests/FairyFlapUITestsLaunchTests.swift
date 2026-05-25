import XCTest

/// Captures launch screenshots across UI configurations for App Store review artifacts.
final class FairyFlapUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchProducesScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
        sleep(1)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
