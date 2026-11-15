import XCTest

/// All Given/When/Then step definitions, mapping Gherkin lines to XCUITest
/// actions/assertions. Keywords are interchangeable at match time, so each step
/// is registered once regardless of whether specs phrase it as Given/When/Then.
///
/// The app runs in mock mode, so the fixture strings below are deterministic:
/// one saved computer ("Studio Mac" at studio.local, user "john", password
/// "secret") and one nearby Mac ("John's Mac mini").
enum StepDefinitions {
    private static let short: TimeInterval = 5
    private static let medium: TimeInterval = 10

    static func makeRegistry() -> StepRegistry {
        let r = StepRegistry()

        // MARK: Lifecycle
        r.define("the app is launched") { _ in }
        r.define("I am connected to \"(.+)\"") { w in
            tap(w.app.buttons["host-\(w.capture())"])
            XCTAssertTrue(remoteScreen(w).waitForExistence(timeout: medium), "remote screen should appear")
        }

        // MARK: Generic
        r.define("I should see \"(.+)\"") { w in
            let text = w.capture()
            let any = w.app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", text)).firstMatch
            XCTAssertTrue(any.waitForExistence(timeout: medium), "“\(text)” should be visible")
        }
        r.define("I tap \"(.+)\"") { w in tap(w.app.buttons[w.capture()]) }
        r.define("the \"(.+)\" button should not be visible") { w in
            let button = w.app.buttons[w.capture()]
            XCTAssertTrue(waitUntil({ !button.exists }, timeout: medium), "\(button) should disappear")
        }
        r.define("the \"(.+)\" button should be disabled") { w in
            let button = w.app.buttons[w.capture()]
            XCTAssertTrue(button.waitForExistence(timeout: short))
            XCTAssertFalse(button.isEnabled)
        }
        r.define("I turn on \"(.+)\"") { w in
            let toggle = w.app.switches[w.capture()]
            XCTAssertTrue(toggle.waitForExistence(timeout: short))
            // Tap the switch knob itself: a tap on the row's label doesn't flip a SwiftUI Toggle.
            if (toggle.value as? String) != "1" {
                toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
            }
            XCTAssertTrue(waitUntil { (toggle.value as? String) == "1" },
                          "\(w.capture()) should be on, value is \(String(describing: toggle.value))")
        }

        // MARK: Computer list
        r.define("the \"(.+)\" computer should be listed") { w in
            XCTAssertTrue(w.app.buttons["host-\(w.capture())"].waitForExistence(timeout: medium))
        }
        r.define("the \"(.+)\" computer should not be listed") { w in
            let row = w.app.buttons["host-\(w.capture())"]
            XCTAssertTrue(waitUntilGone(row), "row should disappear")
        }
        r.define("the \"(.+)\" nearby computer should be listed") { w in
            XCTAssertTrue(w.app.buttons["nearby-\(w.capture())"].waitForExistence(timeout: medium))
        }
        r.define("I tap the \"(.+)\" computer") { w in tap(w.app.buttons["host-\(w.capture())"]) }
        r.define("I tap the \"(.+)\" nearby computer") { w in tap(w.app.buttons["nearby-\(w.capture())"]) }
        r.define("I swipe to delete \"(.+)\"") { w in
            let row = w.app.buttons["host-\(w.capture())"]
            XCTAssertTrue(row.waitForExistence(timeout: short))
            row.swipeLeft()
            tap(w.app.buttons["Delete"])
        }

        // MARK: Forms (editor + sign-in share field identifiers)
        r.define("I enter \"(.+)\" as the (name|hostname|username|port)") { w in
            let field = w.app.textFields[w.capture(1).capitalized]
            XCTAssertTrue(field.waitForExistence(timeout: short))
            field.tap()
            field.typeText(w.capture(0))
        }
        r.define("I enter \"(.+)\" as the password") { w in
            let field = w.app.secureTextFields["Password"]
            XCTAssertTrue(field.waitForExistence(timeout: short))
            field.tap()
            field.typeText(w.capture())
        }
        r.define("the (hostname|username) field should contain \"(.+)\"") { w in
            let field = w.app.textFields[w.capture(0).capitalized]
            XCTAssertTrue(field.waitForExistence(timeout: short))
            XCTAssertEqual(field.value as? String, w.capture(1))
        }

        // MARK: Session
        r.define("I should be asked for a password") { w in
            XCTAssertTrue(w.app.navigationBars["Sign In"].waitForExistence(timeout: medium))
            XCTAssertTrue(w.app.secureTextFields["Password"].exists)
        }
        r.define("I should see the remote screen") { w in
            XCTAssertTrue(remoteScreen(w).waitForExistence(timeout: medium))
        }
        r.define("the status should read \"(.+)\"") { w in
            let status = w.app.staticTexts["status"]
            XCTAssertTrue(status.waitForExistence(timeout: short))
            XCTAssertEqual(status.label, w.capture())
        }
        r.define("I tap the remote screen") { w in remoteScreen(w).tap() }
        r.define("I switch to touchpad mode") { w in
            tap(w.app.buttons["pointerMode"])
            XCTAssertTrue(waitUntil { (w.app.buttons["pointerMode"].value as? String) == "touchpad" })
        }
        r.define("I drag one finger across the remote screen") { w in
            let screen = remoteScreen(w)
            let start = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
            let end = screen.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .fast, thenHoldForDuration: 0.1)
        }
        r.define("the last input should be a left click to the right of center") { w in
            XCTAssertTrue(waitUntil {
                guard let value = remoteScreen(w).value as? String, value.hasPrefix("click left at ") else { return false }
                let parts = value.dropFirst("click left at ".count).split(separator: ",").compactMap { Int($0) }
                return parts.count == 2 && parts[0] > 700 && abs(parts[1] - 400) < 60
            }, "remote screen value was \(String(describing: remoteScreen(w).value))")
        }
        r.define("I pinch to zoom in on the remote screen") { w in
            remoteScreen(w).pinch(withScale: 3, velocity: 2)
        }
        r.define("the \"(.+)\" button should be visible") { w in
            XCTAssertTrue(w.app.buttons[w.capture()].waitForExistence(timeout: short))
        }
        r.define("the last input should be a left click near the middle of the screen") { w in
            XCTAssertTrue(waitUntil {
                guard let value = remoteScreen(w).value as? String, value.hasPrefix("click left at ") else { return false }
                let parts = value.dropFirst("click left at ".count).split(separator: ",").compactMap { Int($0) }
                // Mock screen is 1280×800; the pinch is centered, so the center must still map to the center.
                return parts.count == 2 && abs(parts[0] - 640) < 80 && abs(parts[1] - 400) < 80
            }, "remote screen value was \(String(describing: remoteScreen(w).value))")
        }
        r.define("I dismiss the controls tip") { w in tap(w.app.buttons["Got it"]) }
        r.define("the controls tip should be gone") { w in
            XCTAssertTrue(waitUntilGone(w.app.buttons["Got it"]))
        }
        r.define("the last input should be a left click") { w in
            XCTAssertTrue(waitUntil { (remoteScreen(w).value as? String)?.hasPrefix("click left") == true },
                          "remote screen value was \(String(describing: remoteScreen(w).value))")
        }
        r.define("the last input should be \"(.+)\"") { w in
            let expected = w.capture()
            XCTAssertTrue(waitUntil { (remoteScreen(w).value as? String) == expected },
                          "remote screen value was \(String(describing: remoteScreen(w).value))")
        }
        r.define("I tap the \"(.+)\" key") { w in
            let key = w.app.buttons["key-\(w.capture())"]
            XCTAssertTrue(key.waitForExistence(timeout: medium), "key should exist")
            // The bar scrolls horizontally; bring far keys into view first
            // (hittability can't even be evaluated for an off-screen button).
            let screen = w.app.frame  // not windows.firstMatch: that can be the keyboard's window
            let bar = w.app.scrollViews["keyboardBar"]
            for _ in 0..<5 where !screen.contains(key.frame) {
                XCTAssertTrue(bar.exists, "the key bar should be on screen")
                // The bar's reported frame extends under the system keyboard, so
                // drag along the keys' own row rather than the frame's middle.
                let row = (key.frame.midY - bar.frame.minY) / max(1, bar.frame.height)
                let offLeft = key.frame.minX < screen.minX
                let from = CGVector(dx: offLeft ? 0.1 : 0.9, dy: row), to = CGVector(dx: offLeft ? 0.9 : 0.1, dy: row)
                bar.coordinate(withNormalizedOffset: from)
                    .press(forDuration: 0.05, thenDragTo: bar.coordinate(withNormalizedOffset: to),
                           withVelocity: .slow, thenHoldForDuration: 0.1)
            }
            tap(key)
        }
        r.define("the \"(.+)\" modifier should be (held|released)") { w in
            let key = w.app.buttons["key-\(w.capture(0))"]
            let expected = w.capture(1)
            XCTAssertTrue(waitUntil { (key.value as? String) == expected }, "modifier value was \(String(describing: key.value))")
        }

        // MARK: Settings
        r.define("I swipe down from the top edge") { w in
            let strip = w.app.descendants(matching: .any)["edgeReveal"].firstMatch
            XCTAssertTrue(strip.waitForExistence(timeout: short))
            strip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                .press(forDuration: 0.05, thenDragTo: strip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 4)))
        }
        r.define("I open the link \"(.+)\"") { w in
            guard let url = URL(string: w.capture()) else { return XCTFail("bad url") }
            w.app.open(url)
        }
        r.define("I open Settings") { w in tap(w.app.buttons["Settings"]) }
        r.define("the password field should be focused") { w in
            let field = w.app.secureTextFields["Password"]
            XCTAssertTrue(field.waitForExistence(timeout: short))
            XCTAssertTrue(waitUntil { (field.value(forKey: "hasKeyboardFocus") as? Bool) == true },
                          "password field should have keyboard focus")
        }
        r.define("I choose the \"(.+)\" color depth") { w in tap(w.app.buttons[w.capture()]) }
        r.define("the \"(.+)\" color depth should be selected") { w in
            let segment = w.app.buttons[w.capture()]
            XCTAssertTrue(segment.waitForExistence(timeout: short))
            XCTAssertTrue(segment.isSelected)
        }
        return r
    }

    private static func remoteScreen(_ w: GherkinWorld) -> XCUIElement {
        w.app.descendants(matching: .any)["remoteScreen"].firstMatch
    }

    /// Taps an element; if the session toolbar auto-collapsed, expands it and retries.
    private static func tap(_ element: XCUIElement) {
        for _ in 0..<3 {
            if element.waitForExistence(timeout: 3) {
                element.tap()
                return
            }
            let reveal = XCUIApplication().buttons["Show controls"]
            if reveal.waitForExistence(timeout: 1) { reveal.tap() }
        }
        XCTFail("\(element) should exist")
    }

    private static func waitUntil(_ condition: @escaping () -> Bool, timeout: TimeInterval = short) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        return condition()
    }

    private static func waitUntilGone(_ element: XCUIElement) -> Bool {
        waitUntil { !element.exists }
    }
}
