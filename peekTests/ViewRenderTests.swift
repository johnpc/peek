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
        render(SessionView(session: session, onClose: {}))
        XCTAssertNotNil(session.credentialRequest)
        render(CredentialSheet(session: session))
        session.submitCredential(username: "john", password: "secret", remember: false)
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        XCTAssertNotNil(session.frame)
        render(SessionView(session: session, onClose: {}))
        render(KeyboardBar(session: session))
        render(SessionToolbar(session: session, showKeyboard: .constant(true), onClose: {}))
        session.disconnect()
        render(SessionStatusView(session: session, onClose: {}))
        session.retry()
        session.submitCredential(username: "john", password: "nope", remember: false)
        render(SessionStatusView(session: session, onClose: {}))
    }

    func testRemoteScreenView() {
        guard let frame = MockFrame.render(size: CGSize(width: 200, height: 100)) else {
            return XCTFail("no frame")
        }
        render(RemoteScreenView(frame: frame, screenSize: CGSize(width: 200, height: 100), lastAction: "x") { _, _ in })
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
        XCTAssertTrue(view.canBecomeFirstResponder)
        XCTAssertTrue(view.hasText)
        let representable = KeyInputView(isActive: true, onText: { _ in }, onBackspace: {}, onReturn: {})
        render(representable.frame(width: 1, height: 1))
        render(KeyInputView(isActive: false, onText: { _ in }, onBackspace: {}, onReturn: {}))
    }

    func testGestureViewHandlers() {
        var gestures: [ScreenGesture] = []
        var pinches = 0
        let view = RemoteGestureUIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onGesture = { gestures.append($0) }
        view.onPinch = { _, _ in pinches += 1 }
        view.tapped(UITapGestureRecognizer())
        view.doubleTapped(UITapGestureRecognizer())
        view.secondaryTapped(UITapGestureRecognizer())
        view.dragged(UILongPressGestureRecognizer())
        view.scrolled(UIPanGestureRecognizer())
        view.pinched(UIPinchGestureRecognizer())
        XCTAssertEqual(gestures.count, 4, "tap, double tap, secondary tap, scroll; a .possible long press sends nothing")
        XCTAssertEqual(pinches, 1)
        XCTAssertNil(RemoteGestureUIView(coder: NSCoder()))
        render(RemoteGestureView(onGesture: { _ in }, onPinch: { _, _ in }))
    }
}
