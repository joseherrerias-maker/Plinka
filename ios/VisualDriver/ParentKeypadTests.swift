import XCTest

final class ParentKeypadTests: XCTestCase {
    @MainActor func testVideoParentKeypad() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.joseherrerias.plinka")
        for orientation in [UIDeviceOrientation.portrait, .landscapeRight] {
            XCUIDevice.shared.orientation = orientation
            app.launchArguments = ["--parent-keypad-check"]
            app.launch()
            let save = app.buttons["Save to Photos"]
            XCTAssertTrue(save.waitForExistence(timeout: 90))
            reveal(save, in: app)
            save.tap()
            let prompt = app.staticTexts["parent-prompt"]
            XCTAssertTrue(app.navigationBars["Parent check"].waitForExistence(timeout: 10))
            reveal(prompt, in: app)
            XCTAssertTrue(prompt.exists)
            let next = app.buttons["parent-continue"]
            let answer = app.staticTexts["parent-answer"]
            reveal(next, in: app)
            XCTAssertFalse(next.isEnabled)
            let one = app.buttons["parent-digit-1"]
            reveal(one, in: app)
            one.tap()
            XCTAssertEqual(app.state, .runningForeground, "First digit must not restart the app")
            reveal(answer, in: app)
            XCTAssertEqual(answer.value as? String, "1")
            XCTAssertEqual(app.keyboards.count, 0)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = orientation == .portrait ? "keypad-portrait-first-digit" : "keypad-landscape-first-digit"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            let delete = app.buttons["Delete last digit"]
            reveal(delete, in: app)
            delete.tap()
            reveal(answer, in: app)
            XCTAssertEqual(answer.value as? String, "None")
            // Generated challenges contain distinct digits, so 9999 is always wrong.
            let nine = app.buttons["parent-digit-9"]
            reveal(nine, in: app)
            for _ in 0..<4 { nine.tap() }
            XCTAssertFalse(app.buttons["parent-digit-9"].isEnabled)
            reveal(next, in: app)
            XCTAssertTrue(next.isEnabled)
            next.tap()
            let retry = app.staticTexts["Please try the new numbers above."]
            reveal(retry, in: app)
            XCTAssertTrue(retry.exists)
            reveal(answer, in: app)
            XCTAssertEqual(answer.value as? String, "None")
            reveal(one, in: app)
            one.tap()
            let clear = app.buttons["Clear"]
            reveal(clear, in: app)
            clear.tap()
            reveal(answer, in: app)
            XCTAssertEqual(answer.value as? String, "None")
            reveal(next, in: app)
            XCTAssertFalse(next.isEnabled)
            app.buttons["Cancel"].tap()
            XCTAssertTrue(save.waitForExistence(timeout: 10))
            XCTAssertFalse(prompt.exists)
            XCTAssertEqual(app.state, .runningForeground)
            app.terminate()
        }
    }

    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.isHittable { return }
            app.swipeUp()
        }
        // A previous check may have left the scroll position below this element.
        for _ in 0..<8 {
            if element.isHittable { return }
            app.swipeDown()
        }
        XCTAssertTrue(element.isHittable)
    }
}
