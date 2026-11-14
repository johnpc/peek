import Foundation
import Testing
@testable import peek

/// Exercises the real adapter against a port nobody listens on, so the whole
/// connect → fail → disconnected path runs without a VNC server.
struct RoyalVNCDesktopTests {
    @Test func refusedConnectionReportsAConnectionFailure() async throws {
        let host = SavedHost(name: "nothing", hostname: "127.0.0.1", port: 1)
        let desktop = RoyalVNCDesktop(host: host, options: DesktopOptions(colorDepth: 16, isShared: false, isScalingEnabled: false))
        var events: [RemoteDesktopEvent] = []
        desktop.onEvent = { events.append($0) }
        desktop.connect()
        for _ in 0..<100 where !events.contains(where: { $0 != .state(.connecting) }) {
            try await Task.sleep(for: .milliseconds(100))
        }
        let final = events.last
        guard case .state(.disconnected(let failure))? = final else {
            Issue.record("expected a disconnected state, got \(String(describing: final))")
            return
        }
        #expect(failure != nil)
        #expect(failure?.isAuthentication == false)
        #expect(desktop.snapshot() == nil)
        desktop.supply(nil)
        desktop.send(.move(x: 1, y: 1))
        desktop.send(.text("a"))
        desktop.send(.keyDown(KeySym.tab))
        desktop.send(.keyUp(KeySym.tab))
        desktop.send(.buttonDown(.left, x: -5, y: 1))
        desktop.send(.buttonUp(.right, x: 1, y: 1))
        desktop.send(.scroll(dx: 1, dy: -1, x: 0, y: 0))
        desktop.disconnect()
    }

    @Test func credentialRequestIsAnsweredOnce() {
        let desktop = RoyalVNCDesktop(host: SavedHost(name: "x", hostname: "127.0.0.1", port: 1), options: DesktopOptions())
        var events: [RemoteDesktopEvent] = []
        desktop.onEvent = { events.append($0) }
        var answers = 0
        desktop.receiveCredentialRequest(CredentialRequest(needsUsername: true)) { _ in answers += 1 }
        #expect(events == [.credentialNeeded(CredentialRequest(needsUsername: true))])
        desktop.supply(RemoteCredential(username: "a", password: "b"))
        desktop.supply(RemoteCredential(username: "a", password: "b"))
        #expect(answers == 1)
        desktop.receiveCredentialRequest(CredentialRequest(needsUsername: false)) { _ in answers += 1 }
        desktop.supply(nil)
        #expect(answers == 2)
        desktop.receive(.framebufferUpdated)
        #expect(events.last == .framebufferUpdated)
    }
}
