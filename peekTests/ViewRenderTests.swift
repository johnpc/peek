import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import peek

/// Hosts every screen in a window and lays it out, so view bodies execute and
/// any runtime crash (missing environment, bad binding) fails here.
@MainActor
final class ViewRenderTests: XCTestCase {
    private func render<V: View>(_ view: V) {
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        XCTAssertNotNil(controller.view)
    }

    private func environment(_ args: [String] = ["--uitest-mock"]) -> AppEnvironment {
        MockMode.environment(args)
    }

    func testContentViewRenders() {
        render(ContentView(environment: environment()))
        render(ContentView(environment: environment(["--uitest-mock", "--uitest-no-hosts"])))
    }

    func testHostListAndRows() {
        let env = environment()
        env.discovery.start()
        let model = HostListModel(environment: env)
        render(NavigationStack { HostListView(hosts: env.hosts, discovery: env.discovery, model: model) })
        render(HostRow(host: SavedHost(name: "A", hostname: "a", rememberPassword: true)))
        render(EmptyHostsView())
        render(List { NearbySection(nearby: [MockMode.fixtureNearby]) { _ in } })
        render(List { NearbyStatusRow(status: .searching) })
        render(List { NearbyStatusRow(status: .localNetworkDenied) })
        render(List { NearbyStatusRow(status: .failed("boom")) })
    }

    func testEditorAndSettings() {
        render(HostEditorView(draft: HostDraft(), onSave: { _ in }, onCancel: {}))
        render(SettingsView(settings: environment().settings))
        XCTAssertFalse(SettingsView.version.isEmpty)
    }

    func testSessionScreens() {
        let env = environment()
        let host = env.hosts.hosts[0]
        let session = env.makeSession(for: host)
        render(SessionView(session: session, settings: env.settings, onClose: {}))
        XCTAssertNotNil(session.credentialRequest)
        render(CredentialSheet(session: session))
        session.submitCredential(username: "john", password: "secret", remember: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertNotNil(session.frame)
        render(SessionView(session: session, settings: env.settings, onClose: {}))
        var dismissed = false
        render(GestureTipsView { dismissed = true })
        XCTAssertFalse(dismissed)
        Haptics.click()
        Haptics.dragStart()
        render(KeyboardBar(session: session))
        render(SessionToolbar(session: session, showKeyboard: .constant(true), isCollapsed: .constant(false),
                              isZoomed: true, onFit: {}, onClose: {}))
        render(SessionToolbar(session: session, showKeyboard: .constant(false), isCollapsed: .constant(true),
                              isZoomed: false, onFit: {}, onClose: {}))
        render(PasswordField(text: .constant("x"), revealed: true))
        session.disconnect()
        render(SessionStatusView(session: session, onClose: {}))
        render(ReconnectingPill())
        var toastDismissed = 0
        render(ToastView(text: "Copied from Mac") { toastDismissed += 1 })
        XCTAssertEqual(toastDismissed, 0)
        XCTAssertEqual(MockPasteboard(string: "a").changeCount, 1)
        session.retry()
        session.submitCredential(username: "john", password: "nope", remember: false)
        render(SessionStatusView(session: session, onClose: {}))
    }

    func testRemoteScreenView() {
        guard let frame = MockFrame.render(size: CGSize(width: 200, height: 100)) else {
            return XCTFail("no frame")
        }
        render(RemoteScreenView(frame: frame, screenSize: CGSize(width: 200, height: 100), lastAction: "x",
                                isZoomed: .constant(false), fitRequest: 1) { _, _ in })

        let scroll = RemoteScreenScrollView(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
        var zoomed: [Bool] = []
        scroll.onZoomChanged = { zoomed.append($0) }
        scroll.display(frame, size: CGSize(width: 200, height: 100))
        scroll.layoutIfNeeded()
        XCTAssertEqual(scroll.fitScale, 2, "200 wide fits a 400 viewport at 2x")
        XCTAssertEqual(scroll.minimumZoomScale, 2)
        XCTAssertEqual(scroll.maximumZoomScale, 10)
        XCTAssertFalse(scroll.isZoomed)
        XCTAssertEqual(scroll.contentInset.top, 100, "centered vertically")
        XCTAssertTrue(scroll.content.canScrollWithTwoFingers(), "two fingers scroll the Mac when fit")
        scroll.setZoomScale(4, animated: false)
        XCTAssertTrue(scroll.isZoomed)
        XCTAssertFalse(scroll.content.canScrollWithTwoFingers(), "two fingers pan when zoomed")
        XCTAssertEqual(zoomed.last, true)
        scroll.fit()
        scroll.display(frame, size: CGSize(width: 200, height: 100))
        XCTAssertNil(RemoteScreenScrollView(coder: NSCoder()))
    }

    /// A two-finger pan is, to the scroll view, a content-offset change. Zoom
    /// far in and visit each corner the way a pan would, checking what is
    /// visible and where a tap in the middle of the viewport would land.
    func testZoomedPanReachesEveryCornerAndKeepsClicksAccurate() {
        guard let frame = MockFrame.render(size: CGSize(width: 1280, height: 800)) else { return XCTFail("no frame") }
        let viewport = CGSize(width: 400, height: 250)
        let scroll = RemoteScreenScrollView(frame: CGRect(origin: .zero, size: viewport))
        // Real geometry needs a window: point conversion ignores a detached view's offset.
        let window = UIWindow(frame: CGRect(origin: .zero, size: viewport))
        window.addSubview(scroll)
        window.makeKeyAndVisible()
        scroll.display(frame, size: CGSize(width: 1280, height: 800))
        scroll.layoutIfNeeded()
        scroll.setZoomScale(scroll.maximumZoomScale, animated: false)
        scroll.layoutIfNeeded()
        let zoom = scroll.zoomScale
        XCTAssertEqual(zoom, scroll.fitScale * RemoteScreenScrollView.maximumMagnification, accuracy: 0.001)
        XCTAssertTrue(scroll.isZoomed)
        XCTAssertEqual(scroll.contentInset, .zero, "a magnified screen fills the viewport, nothing to center")
        let maxX = scroll.contentSize.width - viewport.width
        let maxY = scroll.contentSize.height - viewport.height
        XCTAssertGreaterThan(maxX, 0); XCTAssertGreaterThan(maxY, 0)

        let corners: [(name: String, offset: CGPoint, pixel: CGPoint)] = [
            ("top-left", CGPoint(x: 0, y: 0), CGPoint(x: viewport.width / 2 / zoom, y: viewport.height / 2 / zoom)),
            ("top-right", CGPoint(x: maxX, y: 0), CGPoint(x: 1280 - viewport.width / 2 / zoom, y: viewport.height / 2 / zoom)),
            ("bottom-left", CGPoint(x: 0, y: maxY), CGPoint(x: viewport.width / 2 / zoom, y: 800 - viewport.height / 2 / zoom)),
            ("bottom-right", CGPoint(x: maxX, y: maxY), CGPoint(x: 1280 - viewport.width / 2 / zoom, y: 800 - viewport.height / 2 / zoom)),
        ]
        for corner in corners {
            scroll.setContentOffset(corner.offset, animated: false)
            scroll.layoutIfNeeded()
            XCTAssertEqual(scroll.contentOffset, corner.offset, corner.name)
            // A scroll view's coordinate space is content space (bounds origin = offset),
            // so the middle of the viewport is offset + half the viewport.
            let center = CGPoint(x: corner.offset.x + viewport.width / 2, y: corner.offset.y + viewport.height / 2)
            let inContent = scroll.content.convert(center, from: scroll)
            XCTAssertEqual(inContent.x, corner.pixel.x, accuracy: 1, "\(corner.name) x")
            XCTAssertEqual(inContent.y, corner.pixel.y, accuracy: 1, "\(corner.name) y")
            let visible = CGRect(origin: CGPoint(x: corner.offset.x / zoom, y: corner.offset.y / zoom),
                                 size: CGSize(width: viewport.width / zoom, height: viewport.height / zoom))
            XCTAssertTrue(CGRect(x: 0, y: 0, width: 1280, height: 800).contains(visible.insetBy(dx: 0.5, dy: 0.5)), corner.name)
        }
        scroll.fit()
        XCTAssertFalse(scroll.isZoomed)
    }

    func testKeyInputViewForwardsTyping() {
        var typed: [String] = []
        var backspaces = 0
        var returns = 0
        let view = KeyInputUIView()
        view.onText = { typed.append($0) }
        view.onBackspace = { backspaces += 1 }
        view.onReturn = { returns += 1 }
        view.insertText("a")
        view.insertText("\n")
        view.deleteBackward()
        XCTAssertEqual(typed, ["a"])
        XCTAssertEqual(backspaces, 1)
        XCTAssertEqual(returns, 1)
        var actions: [HardwareKeyAction] = []
        view.onHardwareKey = { actions.append($0) }
        XCTAssertEqual(view.handle(keyCode: .keyboardEscape, modifiers: [], characters: ""), .key(.escape))
        view.pressesBegan([], with: nil)
        XCTAssertTrue(actions.isEmpty)
        XCTAssertTrue(view.canBecomeFirstResponder)
        XCTAssertTrue(view.hasText)
        let representable = KeyInputView(isActive: true, onText: { _ in }, onBackspace: {}, onReturn: {})
        render(representable.frame(width: 1, height: 1))
        render(KeyInputView(isActive: false, onText: { _ in }, onBackspace: {}, onReturn: {}))
    }

    func testGestureViewHandlers() {
        var gestures: [ScreenGesture] = []
        let view = RemoteGestureUIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onGesture = { gestures.append($0) }
        view.tapped(UITapGestureRecognizer())
        view.doubleTapped(UITapGestureRecognizer())
        view.secondaryTapped(UITapGestureRecognizer())
        view.dragged(UILongPressGestureRecognizer())
        view.scrolled(UIPanGestureRecognizer())
        XCTAssertEqual(gestures.count, 4, "tap, double tap, secondary tap, scroll; a .possible long press sends nothing")
        XCTAssertTrue(view.gestureRecognizerShouldBegin(UITapGestureRecognizer()), "other recognizers are never gated")
        view.hovered(UIHoverGestureRecognizer())
        XCTAssertEqual(gestures.count, 4, "a .possible hover sends nothing")
        let swipe = UISwipeGestureRecognizer(); swipe.direction = .up
        view.swiped(swipe)
        XCTAssertEqual(gestures.last, .swipe(.up))
        XCTAssertNil(SwipeDirection(UISwipeGestureRecognizer.Direction(rawValue: 0)))
        XCTAssertEqual(SwipeDirection(.left), .left)
        XCTAssertEqual(SwipeDirection(.right), .right)
        XCTAssertEqual(SwipeDirection(.down), .down)
        let ringsBefore = view.layer.sublayers?.count ?? 0
        view.showRipple(at: CGPoint(x: 10, y: 10))
        XCTAssertEqual(view.layer.sublayers?.count, ringsBefore + 1, "ripple layer added")
        view.canScrollWithTwoFingers = { false }
        XCTAssertFalse(view.gestureRecognizerShouldBegin(view.twoFingerScroll))
        XCTAssertFalse(view.gestureRecognizerShouldBegin(view.pointerScroll))
        view.canScrollWithTwoFingers = { true }
        XCTAssertTrue(view.gestureRecognizerShouldBegin(view.twoFingerScroll))
        XCTAssertNil(RemoteGestureUIView(coder: NSCoder()))
    }
}
