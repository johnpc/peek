import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import peek

struct VNCSessionTests {
    let host = SavedHost(name: "Studio", hostname: "studio.local", username: "john")

    private func makeSession(savedPassword: String? = nil, configure: @escaping (MockDesktop) -> Void = { _ in })
        -> (VNCSession, () -> MockDesktop?) {
        var current: MockDesktop?
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: host, savedPassword: savedPassword, throttle: throttle) {
            let desktop = MockDesktop()
            configure(desktop)
            current = desktop
            return desktop
        }
        return (session, { current })
    }

    @Test func asksForCredentialWhenNoneSaved() {
        let (session, desktop) = makeSession()
        #expect(session.state == .idle)
        session.connect()
        #expect(session.state == .connecting)
        #expect(session.credentialRequest == CredentialRequest(needsUsername: true))
        session.submitCredential(username: "john", password: "secret", remember: false)
        #expect(session.credentialRequest == nil)
        #expect(session.state == .connected)
        #expect(session.screenSize == CGSize(width: 1280, height: 800))
        #expect(session.frame != nil)
        #expect(desktop()?.suppliedCredentials.first == RemoteCredential(username: "john", password: "secret"))
    }

    @Test func savedPasswordIsSuppliedAutomatically() {
        let (session, desktop) = makeSession(savedPassword: "secret")
        session.connect()
        #expect(session.credentialRequest == nil)
        #expect(session.state == .connected)
        #expect(desktop()?.suppliedCredentials.count == 1)
    }

    @Test func wrongPasswordFailsThenRetryAsksAgain() {
        let (session, _) = makeSession(savedPassword: "wrong")
        session.connect()
        #expect(session.state == .disconnected(.authentication(MockDesktop.rejectionMessage)))
        session.retry()
        #expect(session.state == .connecting)
        #expect(session.credentialRequest != nil, "the rejected saved password must not be reused")
    }

    @Test func rememberIsHonoredOnlyAfterSuccess() {
        let (session, _) = makeSession()
        var remembered: [String] = []
        session.onRememberPassword = { remembered.append($0) }
        session.connect()
        session.submitCredential(username: "john", password: "bad", remember: true)
        #expect(remembered.isEmpty)
        session.retry()
        session.submitCredential(username: "john", password: "secret", remember: true)
        #expect(remembered == ["secret"])
    }

    @Test func cancelAndDisconnect() {
        let (session, desktop) = makeSession()
        session.connect()
        session.cancelCredential()
        #expect(session.state == .disconnected(nil))
        #expect(desktop()?.suppliedCredentials == [nil])
        session.retry()
        session.submitCredential(username: "john", password: "secret", remember: false)
        session.cancelCredential()
        #expect(session.state == .connected, "a late cancel after submitting must not disconnect")
        session.disconnect()
        #expect(session.state == .disconnected(nil))
        #expect(desktop()?.disconnectCount == 1)
        #expect(desktop()?.snapshot() == nil)
    }

    @Test func appleRemoteDesktopServersSwitchTheModifierKeymap() {
        let (session, _) = makeSession(savedPassword: "secret")
        #expect(session.modifiers.keymap == .standard)
        session.connect()
        #expect(session.modifiers.keymap == .appleRemoteDesktop)
        session.toggle(.command)
        let (plain, _) = makeSession { $0.requiresCredential = false }
        plain.connect()
        #expect(plain.modifiers.keymap == .standard)
    }

    @Test func noPasswordServersConnectDirectly() {
        let (session, _) = makeSession { $0.requiresCredential = false }
        session.connect()
        #expect(session.state == .connected)
        #expect(session.credentialRequest == nil)
    }
}

struct SessionLifecycleTests {
    private func connectedSession() -> (VNCSession, () -> Int) {
        var connects = 0
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: SavedHost(name: "S", hostname: "s"), throttle: throttle) {
            connects += 1
            let desktop = MockDesktop()
            desktop.requiresCredential = false
            return desktop
        }
        session.connect()
        return (session, { connects })
    }

    @Test func reconnectsAfterALongBackgroundStayOnly() {
        let (session, connects) = connectedSession()
        let lifecycle = SessionLifecycle()
        var clock = Date(timeIntervalSince1970: 1_000)
        lifecycle.now = { clock }
        lifecycle.update(.background, session: session)
        #expect(lifecycle.backgroundedAt == clock)
        clock = clock.addingTimeInterval(5)
        lifecycle.update(.active, session: session)
        #expect(connects() == 1, "a short background stay keeps the connection")
        lifecycle.update(.background, session: session)
        clock = clock.addingTimeInterval(60)
        lifecycle.update(.active, session: session)
        #expect(connects() == 2, "a long background stay reconnects")
        #expect(lifecycle.backgroundedAt == nil)
        lifecycle.update(.inactive, session: session)
        #expect(connects() == 2)
    }

    @Test func reconnectsAfterADroppedConnection() {
        let (session, connects) = connectedSession()
        session.desktop?.onEvent?(.state(.disconnected(.connection("dropped"))))
        SessionLifecycle().update(.active, session: session)
        #expect(connects() == 2)
    }
}

struct VNCSessionInputTests {
    private func connected() -> (VNCSession, MockDesktop) {
        let desktop = MockDesktop()
        desktop.requiresCredential = false
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: SavedHost(name: "S", hostname: "s"), throttle: throttle) { desktop }
        session.connect()
        return (session, desktop)
    }

    @Test func gesturesBecomeClicksWithALastAction() {
        let (session, desktop) = connected()
        let transform = ScreenTransform(scale: 1, offset: .zero)
        session.perform(.tap(CGPoint(x: 10, y: 20)), transform: transform)
        #expect(desktop.inputs.count == 3)
        #expect(session.lastAction == "click left at 10,20")
        session.perform(.doubleTap(.zero), transform: transform)
        #expect(session.lastAction == "double click at 0,0")
        session.perform(.secondaryTap(CGPoint(x: 1, y: 1)), transform: transform)
        #expect(session.lastAction == "click right at 1,1")
        session.perform(.dragBegan(.zero), transform: transform)
        #expect(session.lastAction == "drag start at 0,0")
        session.perform(.dragMoved(CGPoint(x: 2, y: 2)), transform: transform)
        #expect(session.lastAction == "drag at 2,2")
        session.perform(.dragEnded(CGPoint(x: 3, y: 3)), transform: transform)
        #expect(session.lastAction == "drag end at 3,3")
        session.perform(.scroll(steps: CGSize(width: 0, height: 2), at: .zero), transform: transform)
        #expect(session.lastAction == "scroll 0,2")
        let before = desktop.inputs.count
        session.perform(.scroll(steps: .zero, at: .zero), transform: transform)
        #expect(desktop.inputs.count == before, "empty gestures send nothing")
    }

    @Test func keysTextAndStickyModifiers() {
        let (session, desktop) = connected()
        session.toggle(.command)
        #expect(session.heldModifiers == [.command])
        #expect(session.lastAction == "hold ⌘")
        session.press(.tab)
        #expect(session.lastAction == "key tab")
        #expect(session.heldModifiers.isEmpty)
        #expect(desktop.inputs.suffix(3) == [.keyDown(KeySym.tab), .keyUp(KeySym.tab), .keyUp(KeySym.superLeft)])
        session.toggle(.shift)
        session.toggle(.shift)
        #expect(session.lastAction == "release ⇧")
        session.type("hi")
        #expect(desktop.inputs.last == .text("hi"))
        #expect(session.lastAction == "text hi")
        session.type("")
        #expect(session.lastAction == "text hi")
    }

    @Test func describeScrollWithoutLocation() {
        #expect(VNCSession.describe(.scroll(steps: CGSize(width: 1, height: 0), at: .zero), inputs: []) == "scroll 1,0")
        #expect(VNCSession.describe(.tap(.zero), inputs: [.text("x")]) == "click left")
    }
}

struct MockDesktopTests {
    @Test func paintsAFrameOnlyWhileConnected() {
        let desktop = MockDesktop()
        desktop.requiresCredential = false
        #expect(desktop.snapshot() == nil)
        desktop.connect()
        let frame = desktop.snapshot()
        #expect(frame?.width == 1280)
        #expect(desktop.snapshot() === frame, "frame is cached")
        desktop.disconnect()
        #expect(desktop.snapshot() == nil)
        #expect(MockFrame.render(size: .zero) == nil)
    }
}
