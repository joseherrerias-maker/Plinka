import XCTest

final class EditorTests: XCTestCase {
    @MainActor func testNamingAndClearConfirmation() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.joseherrerias.plinka")
        for orientation in [UIDeviceOrientation.portrait, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            app.launchArguments = ["--editor-check"]
            app.launch()
            let menu = app.buttons["Song menu"]
            XCTAssertTrue(menu.waitForExistence(timeout: 15))
            menu.tap()
            let rename = app.buttons["rename-song"]
            XCTAssertTrue(rename.waitForExistence(timeout: 5))
            let original = rename.label
            rename.tap()
            let field = app.textFields["rename-song-name"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
            XCTAssertTrue(field.isHittable)
            XCTAssertLessThan(field.frame.maxY, app.keyboards.firstMatch.frame.minY)
            field.typeText(" Test")
            app.buttons["Cancel"].tap()
            menu.tap()
            XCTAssertEqual(rename.label, original, "Cancel must preserve the title")
            rename.tap()
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
            field.typeText(" Test")
            app.navigationBars["Rename song"].buttons["Done"].tap()
            menu.tap()
            XCTAssertTrue(rename.label.hasSuffix(" Test"))
            let save = app.buttons["Save song"]
            if !save.isHittable { app.scrollViews.firstMatch.swipeUp() }
            save.tap()
            let saveField = app.textFields["save-song-name"]
            XCTAssertTrue(saveField.waitForExistence(timeout: 5))
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10))
            XCTAssertTrue(saveField.isHittable)
            XCTAssertLessThan(saveField.frame.maxY, app.keyboards.firstMatch.frame.minY)
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "save-name-\(orientation.rawValue)"
            shot.lifetime = .keepAlways
            add(shot)
            app.navigationBars["Save song"].buttons["Save"].tap()
            let clear = app.buttons["Clear all notes"]
            XCTAssertTrue(clear.waitForExistence(timeout: 5))
            clear.tap()
            let alert = app.alerts["Clear all notes?"]
            XCTAssertTrue(alert.waitForExistence(timeout: 5))
            XCTAssertEqual(alert.frame.midX, app.frame.midX, accuracy: 40)
            alert.buttons["Cancel"].tap()
            XCTAssertTrue(clear.isEnabled)
            clear.tap()
            alert.buttons["Clear notes"].tap()
            XCTAssertFalse(clear.isEnabled)
            app.buttons["Undo"].tap()
            XCTAssertTrue(clear.isEnabled, "Undo must restore cleared notes")
            app.terminate()
        }
    }
}
