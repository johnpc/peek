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
            XCTAssertTrue(waitUntilGone(w.app.buttons[w.capture()]))
        }
        r.define("the \"(.+)\" button should be disabled") { w in
            let button = w.app.buttons[w.capture()]
            XCTAssertTrue(button.waitForExistence(timeout: short))
            XCTAssertFalse(button.isEnabled)
        }
        r.define("I turn on \"(.+)\"") { w in
            let toggle = w.app.switches[w.capture()]
            XCTAssertTrue(toggle.waitForExistence(timeout: short))
            if (toggle.value as? String) != "1" { toggle.tap() }
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
        r.define("I tap the \"(.+)\" key") { w in tap(w.app.buttons["key-\(w.capture())"]) }
        r.define("the \"(.+)\" modifier should be (held|released)") { w in
            let key = w.app.buttons["key-\(w.capture(0))"]
            let expected = w.capture(1)
            XCTAssertTrue(waitUntil { (key.value as? String) == expected }, "modifier value was \(String(describing: key.value))")
        }

        // MARK: Settings
        r.define("I open Settings") { w in tap(w.app.buttons["Settings"]) }
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

    private static func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: medium), "\(element) should exist")
        element.tap()
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
