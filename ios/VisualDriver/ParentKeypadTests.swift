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
        // Query the presented sheet by its contents, never by a cached index.
        // In landscape, a drag starting at 20% of the full screen can hit the
        // navigation area and dismiss the sheet instead of scrolling it.
        for attempt in 0..<12 {
            let parentNavigation = app.navigationBars["Parent check"]
            let isParent = parentNavigation.exists
            let navigation = isParent ? parentNavigation : app.navigationBars["Export video"]
            let scroll = isParent
                ? app.scrollViews.containing(.staticText, identifier: "parent-prompt").firstMatch
                : app.scrollViews.containing(.button, identifier: "Save to Photos").firstMatch
            guard navigation.exists && scroll.exists else {
                XCTFail("Expected the export or parent-check sheet to remain open")
                return
            }
            let frame = scroll.frame.intersection(app.frame)
            let top = max(frame.minY, navigation.frame.maxY) + 12
            let bottom = frame.maxY - 12
            let viewport = CGRect(x: frame.minX + 8, y: top,
                                  width: frame.width - 16, height: bottom - top)
            guard viewport.height > 44 else {
                XCTFail("The sheet must have visible scrollable content")
                return
            }
            if element.exists && element.isHittable &&
                viewport.contains(CGPoint(x: element.frame.midX, y: element.frame.midY)) {
                return
            }
            let upward = element.exists ? element.frame.midY > viewport.midY : attempt < 6
            let upper = viewport.minY + viewport.height * 0.20
            let lower = viewport.minY + viewport.height * 0.85
            let origin = app.coordinate(withNormalizedOffset: .zero)
            let start = origin.withOffset(CGVector(dx: viewport.maxX - 4 - app.frame.minX,
                                                   dy: (upward ? lower : upper) - app.frame.minY))
            let end = origin.withOffset(CGVector(dx: viewport.maxX - 4 - app.frame.minX,
                                                 dy: (upward ? upper : lower) - app.frame.minY))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTFail("Control must be visible below the navigation bar before tapping")
    }
}
