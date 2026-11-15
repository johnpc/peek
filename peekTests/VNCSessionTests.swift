import CoreGraphics
import Foundation
import SwiftUI
import UIKit
import Testing
@testable import peek

struct VNCSessionTests {
    let host = SavedHost(name: "Studio", hostname: "studio.local", username: "john")

    private func makeSession(savedPassword: String? = nil, configure: @escaping (MockDesktop) -> Void = { _ in })
        -> (VNCSession, () -> MockDesktop?) {
        var current: MockDesktop?
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: host, savedPassword: savedPassword, throttle: throttle) { _ in
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

    @Test func savedPasswordIsReusedOnReconnect() {
        let (session, desktop) = makeSession(savedPassword: "secret")
        session.connect()
        #expect(session.state == .connected)
        desktop()?.onEvent?(.state(.disconnected(.connection("dropped"))))
        session.retry()
        #expect(session.credentialRequest == nil, "a dropped connection must not ask for the password again")
        #expect(session.state == .connected)
    }

    @Test func typedPasswordIsReusedOnReconnectEvenWithoutRemember() {
        let (session, desktop) = makeSession()
        session.connect()
        session.submitCredential(username: "john", password: "secret", remember: false)
        #expect(session.state == .connected)
        #expect(session.frame != nil)
        desktop()?.onEvent?(.state(.disconnected(.connection("dropped"))))
        session.retry()
        #expect(session.frame != nil, "the last frame stays up while reconnecting")
        #expect(session.credentialRequest == nil)
        #expect(session.state == .connected)
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
        let session = VNCSession(host: SavedHost(name: "S", hostname: "s"), throttle: throttle) { _ in
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
        let lifecycle = SessionLifecycle(beginHold: { _ in .invalid }, endHold: { _ in })
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

    @Test func holdsABackgroundTaskUntilActiveAgain() {
        let (session, _) = connectedSession()
        var began = 0, ended: [UIBackgroundTaskIdentifier] = []
        let lifecycle = SessionLifecycle(
            beginHold: { _ in began += 1; return UIBackgroundTaskIdentifier(rawValue: 42) },
            endHold: { ended.append($0) })
        lifecycle.update(.background, session: session)
        lifecycle.update(.background, session: session)
        #expect(began == 1, "one hold per background stay")
        #expect(lifecycle.hold.rawValue == 42)
        lifecycle.update(.active, session: session)
        #expect(ended == [UIBackgroundTaskIdentifier(rawValue: 42)])
        #expect(lifecycle.hold == .invalid)
    }

    @Test func expiredHoldIsReleasedOnce() {
        let (session, _) = connectedSession()
        var expiry: (() -> Void)?
        var ended = 0
        let lifecycle = SessionLifecycle(
            beginHold: { handler in expiry = handler; return UIBackgroundTaskIdentifier(rawValue: 7) },
            endHold: { _ in ended += 1 })
        lifecycle.update(.background, session: session)
        expiry?()
        lifecycle.update(.active, session: session)
        #expect(ended == 1)
    }

    @Test func reconnectsAfterADroppedConnection() {
        let (session, connects) = connectedSession()
        session.desktop?.onEvent?(.state(.disconnected(.connection("dropped"))))
        SessionLifecycle(beginHold: { _ in .invalid }, endHold: { _ in }).update(.active, session: session)
        #expect(connects() == 2)
    }
}

struct VNCSessionResolveTests {
    private let nearby = SavedHost(name: "Mini", hostname: "10.0.0.5", serviceName: "John's Mac mini")

    private func run(resolver: MockResolver) async -> (VNCSession, [String], [String]) {
        var dialed: [String] = []
        var changes: [String] = []
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: nearby, throttle: throttle, resolver: resolver) { target in
            dialed.append(target.hostname)
            let desktop = MockDesktop()
            desktop.requiresCredential = false
            return desktop
        }
        session.onAddressChanged = { changes.append($0) }
        session.connect()
        #expect(session.state == .connecting)
        for _ in 0..<50 where session.state != .connected { try? await Task.sleep(for: .milliseconds(10)) }
        return (session, dialed, changes)
    }

    @Test func dialsTheFreshlyResolvedAddressAndReportsIt() async {
        let resolver = MockResolver(answers: ["John's Mac mini": "10.0.0.9"])
        let (session, dialed, changes) = await run(resolver: resolver)
        #expect(session.state == .connected)
        #expect(dialed == ["10.0.0.9"])
        #expect(changes == ["10.0.0.9"])
        #expect(resolver.requests == ["John's Mac mini"])
    }

    @Test func fallsBackToTheSavedAddressWhenResolutionFails() async {
        let (session, dialed, changes) = await run(resolver: MockResolver())
        #expect(session.state == .connected)
        #expect(dialed == ["10.0.0.5"])
        #expect(changes.isEmpty)
    }

    @Test func plainHostsSkipResolution() {
        let resolver = MockResolver(answers: ["x": "y"])
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: SavedHost(name: "S", hostname: "s"), throttle: throttle, resolver: resolver) { _ in
            let desktop = MockDesktop(); desktop.requiresCredential = false; return desktop
        }
        session.connect()
        #expect(session.state == .connected)
        #expect(resolver.requests.isEmpty)
    }
}

struct VNCSessionInputTests {
    private func connected() -> (VNCSession, MockDesktop) {
        let desktop = MockDesktop()
        desktop.requiresCredential = false
        let throttle = FrameThrottle(interval: 0) { _, work in work() }
        let session = VNCSession(host: SavedHost(name: "S", hostname: "s"), throttle: throttle) { _ in desktop }
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

    @Test func hardwareChordsHoldModifiersAroundText() {
        let (session, desktop) = connected()
        session.chord([.command, .shift], text: "z")
        #expect(session.lastAction == "⌘⇧z")
        #expect(desktop.inputs.suffix(5) == [
            .keyDown(KeySym.superLeft), .keyDown(KeySym.shiftLeft), .text("z"),
            .keyUp(KeySym.shiftLeft), .keyUp(KeySym.superLeft),
        ])
        session.toggle(.control)
        session.chord([.command], text: "c")
        #expect(session.heldModifiers.isEmpty, "sticky modifiers release after a chord")
        #expect(desktop.inputs.last == .keyUp(KeySym.controlLeft))
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
