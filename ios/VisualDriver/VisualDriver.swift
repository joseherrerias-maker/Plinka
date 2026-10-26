import XCTest

final class VisualDriver: XCTestCase {
    @MainActor func testVisualTour() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication(bundleIdentifier: "com.joseherrerias.plinka")
        app.launchArguments = ["--visual-tour"]
        app.launch()
        let stage = app.staticTexts["visual-stage"]
        XCTAssertTrue(stage.waitForExistence(timeout: 60))
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "rotate-landscape"), object: stage)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 300), .completed)
        XCUIDevice.shared.orientation = .landscapeRight
        let finished = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "finished"), object: stage)
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 300), .completed)
    }
}
