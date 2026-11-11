import XCTest

final class VisualDriver: XCTestCase {
    @MainActor func testStudioCapture() {
        continueAfterFailure = false
        let landscape = UIDevice.current.userInterfaceIdiom == .pad
        XCUIDevice.shared.orientation = landscape ? .landscapeRight : .portrait
        let app = XCUIApplication(bundleIdentifier: "com.joseherrerias.plinka")
        app.launchArguments = ["--studio-capture"] + (landscape ? ["--studio-landscape"] : [])
        app.launch()
        let stage = app.staticTexts["visual-stage"]
        XCTAssertTrue(stage.waitForExistence(timeout: 60))
        let animals = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "choose-animals"), object: stage)
        XCTAssertEqual(XCTWaiter.wait(for: [animals], timeout: 180), .completed)
        let animalTab = app.buttons["Animals"]
        XCTAssertTrue(animalTab.waitForExistence(timeout: 10))
        animalTab.tap()
        let instruments = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "choose-instruments"), object: stage)
        XCTAssertEqual(XCTWaiter.wait(for: [instruments], timeout: 60), .completed)
        app.buttons["Instruments"].tap()
        let finished = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "finished"), object: stage)
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 240), .completed)
    }
}
