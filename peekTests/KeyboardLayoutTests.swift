import SwiftUI
import UIKit
import XCTest
@testable import peek

/// The key bar rides on the keyboard and the remote screen re-fits above it.
@MainActor
final class KeyboardLayoutTests: XCTestCase {
    func testObscuredHeightIsTheKeyboardOverlap() {
        let viewport = CGRect(x: 0, y: 0, width: 400, height: 800)
        XCTAssertEqual(RemoteScreenScrollView.obscuredHeight(viewport: viewport, keyboard: CGRect(x: 0, y: 500, width: 400, height: 300)), 300)
        XCTAssertEqual(RemoteScreenScrollView.obscuredHeight(viewport: viewport, keyboard: CGRect(x: 0, y: 800, width: 400, height: 300)), 0,
                       "a dismissed keyboard sits below the view")
        XCTAssertEqual(RemoteScreenScrollView.obscuredHeight(viewport: viewport, keyboard: .zero), 0)
        XCTAssertEqual(RemoteScreenScrollView.obscuredHeight(viewport: viewport, keyboard: CGRect(x: 0, y: -10, width: 400, height: 900)), 800)
    }

    func testScreenRefitsAboveTheKeyboard() throws {
        let frame = try XCTUnwrap(MockFrame.render(size: CGSize(width: 200, height: 100)))
        let scroll = RemoteScreenScrollView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        window.addSubview(scroll)
        window.makeKeyAndVisible()
        scroll.display(frame, size: CGSize(width: 200, height: 100))
        scroll.layoutIfNeeded()
        XCTAssertEqual(scroll.fitScale, 2, "width-bound without a keyboard")
        XCTAssertEqual(scroll.contentInset.top, 300)

        let info: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 100, width: 400, height: 700)),
            UIResponder.keyboardAnimationDurationUserInfoKey: 0.0,
        ]
        NotificationCenter.default.post(name: UIResponder.keyboardWillChangeFrameNotification, object: nil, userInfo: info)
        XCTAssertEqual(scroll.keyboardOverlap, 700)
        scroll.layoutIfNeeded()
        XCTAssertEqual(scroll.visibleHeight, 100)
        XCTAssertEqual(scroll.fitScale, 1, "now height-bound by the 100pt left above the keyboard")
        XCTAssertEqual(scroll.minimumZoomScale, 1)
        XCTAssertEqual(scroll.zoomScale, 1, accuracy: 0.001)
        XCTAssertEqual(scroll.contentInset.top, 0)
        XCTAssertEqual(scroll.contentInset.bottom, 700, "the hidden part is scrollable")

        NotificationCenter.default.post(name: UIResponder.keyboardWillChangeFrameNotification, object: nil,
                                        userInfo: [UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 800, width: 400, height: 700))])
        XCTAssertEqual(scroll.keyboardOverlap, 0)
        scroll.setKeyboardOverlap(0, duration: 0)
        NotificationCenter.default.post(name: UIResponder.keyboardWillChangeFrameNotification, object: nil, userInfo: nil)
        XCTAssertEqual(scroll.keyboardOverlap, 0, "a malformed notification changes nothing")

        let detached = RemoteScreenScrollView(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        detached.keyboardWillChangeFrame(Notification(name: UIResponder.keyboardWillChangeFrameNotification, object: nil, userInfo: info))
        XCTAssertEqual(detached.keyboardOverlap, 0, "off-window views ignore the keyboard")
    }

    func testKeyBarIsTheKeyboardAccessory() {
        let input = KeyInputUIView()
        XCTAssertNil(input.inputAccessoryView)
        let accessory = KeyboardAccessoryView(height: KeyboardBar.height, content: AnyView(Text("bar")))
        input.accessoryHost = accessory
        XCTAssertTrue(input.inputAccessoryView === accessory)
        XCTAssertEqual(accessory.frame.height, 54)
        XCTAssertEqual(accessory.subviews.count, 1)
        accessory.update(AnyView(Text("updated")))
        accessory.frame.size.width = 500
        accessory.layoutIfNeeded()
        XCTAssertEqual(accessory.subviews.first?.frame.width, 500, "the bar stretches with the keyboard")
        XCTAssertNil(KeyboardAccessoryView<AnyView>(coder: NSCoder()))

        let session = MockMode.environment(["--uitest-mock"]).makeSession(for: SavedHost(name: "m", hostname: "mock", port: 5900))
        let view = KeyInputView(isActive: true, onText: { _ in }, onBackspace: {}, onReturn: {},
                                accessory: AnyView(KeyboardBar(session: session)))
        let controller = UIHostingController(rootView: view.frame(width: 1, height: 1))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        let hosted = controller.view.subviews.compactMap { $0 as? KeyInputUIView }.first
            ?? controller.view.subviews.flatMap(\.subviews).compactMap { $0 as? KeyInputUIView }.first
        XCTAssertNotNil(hosted?.inputAccessoryView, "the key bar is attached to the keyboard")
    }
}
