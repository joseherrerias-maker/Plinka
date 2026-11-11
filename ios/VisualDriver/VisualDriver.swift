import XCTest

final class VisualDriver: XCTestCase {
    @MainActor func testStudioCapture() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeRight
        let app = XCUIApplication(bundleIdentifier: "com.joseherrerias.plinka")
        app.launchArguments = ["--studio-capture", "--studio-landscape"]
        app.launch()
        // Avoid repeated accessibility snapshots while the host reads native screenshots.
        Thread.sleep(forTimeInterval: 180)
        XCTAssertEqual(app.staticTexts["visual-stage"].label, "finished")
    }
}
