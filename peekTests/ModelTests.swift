import Foundation
import Testing
@testable import peek

struct SavedHostTests {
    @Test func addressHidesDefaultPort() {
        #expect(SavedHost(name: "Mac", hostname: "mac.local").address == "mac.local")
        #expect(SavedHost(name: "Mac", hostname: "mac.local", port: 5901).address == "mac.local:5901")
    }

    @Test func displayNameFallsBackToHostname() {
        #expect(SavedHost(name: "", hostname: "mac.local").displayName == "mac.local")
        #expect(SavedHost(name: "Studio", hostname: "mac.local").displayName == "Studio")
    }

    @Test func subtitleFlagsNearbyHosts() {
        #expect(SavedHost(name: "A", hostname: "mac.local").subtitle == "mac.local")
        #expect(SavedHost(name: "A", hostname: "fe80::1%en0", serviceName: "Mini").subtitle == "Nearby · fe80::1%en0")
    }

    @Test func decodesRecordsSavedBeforeServiceNameExisted() throws {
        let legacy = Data("""
        {"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"A","hostname":"a.local","port":5900,"username":"","rememberPassword":false}
        """.utf8)
        let host = try JSONDecoder().decode(SavedHost.self, from: legacy)
        #expect(host.serviceName == nil)
        #expect(host.hostname == "a.local")
    }

    @Test func roundTripsThroughJSON() throws {
        let host = SavedHost(name: "Studio", hostname: "studio.local", port: 5901, username: "john", rememberPassword: true)
        let data = try JSONEncoder().encode(host)
        let decoded = try JSONDecoder().decode(SavedHost.self, from: data)
        #expect(decoded == host)
    }

    @Test func discoveredHostBecomesSavedHost() {
        let nearby = DiscoveredHost(serviceName: "Mini", hostname: "10.0.0.5", port: 5900)
        let saved = nearby.asSavedHost()
        #expect(saved.serviceName == "Mini")
        #expect(saved.name == "Mini")
        #expect(saved.hostname == "10.0.0.5")
        #expect(saved.port == 5900)
        #expect(nearby.id == "Mini")
    }
}

struct RemoteStateTests {
    @Test func labelsAndFlags() {
        #expect(RemoteState.idle.label == "Not connected")
        #expect(RemoteState.connecting.label == "Connecting…")
        #expect(RemoteState.connected.label == "Connected")
        #expect(RemoteState.disconnected(nil).label == "Disconnected")
        #expect(RemoteState.disconnected(.connection("Nope")).label == "Nope")
        #expect(RemoteState.connecting.isActive)
        #expect(!RemoteState.disconnected(nil).isActive)
        #expect(!RemoteState.idle.isActive)
        #expect(RemoteState.idle.failure == nil)
    }

    @Test func failureMessages() {
        let auth = RemoteFailure.authentication("Bad password")
        #expect(auth.message == "Bad password")
        #expect(auth.isAuthentication)
        #expect(!RemoteFailure.connection("Down").isAuthentication)
        #expect(RemoteState.disconnected(auth).failure == auth)
    }
}

struct RemoteInputTests {
    @Test func modifierKeymaps() {
        let standard = ModifierKeymap.standard
        #expect(standard.keysym(for: .command) == KeySym.superLeft)
        #expect(standard.keysym(for: .option) == KeySym.altLeft)
        #expect(standard.keysym(for: .control) == KeySym.controlLeft)
        #expect(standard.keysym(for: .shift) == KeySym.shiftLeft)
        let apple = ModifierKeymap.appleRemoteDesktop
        #expect(apple.keysym(for: .command) == KeySym.hyperLeft)
        #expect(apple.keysym(for: .option) == KeySym.metaLeft)
        #expect(apple.keysym(for: .control) == KeySym.controlLeft)
        #expect(apple.keysym(for: .shift) == KeySym.shiftLeft)
        #expect(Modifier.allCases.map(\.symbol) == ["⌘", "⌥", "⌃", "⇧"])
    }

    @Test func keysHaveLabelsAndKeysyms() {
        for key in RemoteKey.allCases {
            #expect(!key.label.isEmpty)
            #expect(key.keysym != 0)
        }
        #expect(RemoteKey.escape.keysym == KeySym.escape)
        #expect(RemoteKey.delete.keysym == KeySym.backspace)
        #expect(RemoteKey.forwardDelete.keysym == KeySym.delete)
        #expect(RemoteKey.return.label == "return")
        #expect(RemoteKey.upArrow.keysym == KeySym.up)
        #expect(RemoteKey.downArrow.keysym == KeySym.down)
        #expect(RemoteKey.leftArrow.keysym == KeySym.left)
        #expect(RemoteKey.rightArrow.keysym == KeySym.right)
        #expect(RemoteKey.tab.keysym == KeySym.tab)
    }

    @Test func functionKeysAndMacActions() {
        #expect(KeySym.function(1) == 0xffbe)
        #expect(KeySym.function(12) == 0xffc9)
        #expect(KeySym.function(99) == 0xffc9, "clamped")
        #expect(KeyChord.functionKeys.count == 12)
        #expect(KeyChord.functionKeys.first?.label == "F1")
        #expect(KeyChord.functionKeys.last?.keysym == KeySym.function(12))
        #expect(KeyChord.macActions.map(\.label).contains("Lock Screen"))
        #expect(KeyChord.macActions.first { $0.label == "Spotlight" }?.modifiers == [.command])
        #expect(Set(KeyChord.macActions.map(\.id)).count == KeyChord.macActions.count, "labels are unique ids")
    }

    @Test func summaries() {
        #expect(RemoteInput.move(x: 1, y: 2).summary == "move to 1,2")
        #expect(RemoteInput.buttonDown(.left, x: 1, y: 2).summary == "left down at 1,2")
        #expect(RemoteInput.buttonUp(.right, x: 3, y: 4).summary == "right up at 3,4")
        #expect(RemoteInput.scroll(dx: 0, dy: 1, x: 5, y: 6).summary == "scroll 0,1 at 5,6")
        #expect(RemoteInput.keyDown(7).summary == "key down 7")
        #expect(RemoteInput.keyUp(7).summary == "key up 7")
        #expect(RemoteInput.text("hi").summary == "text hi")
        #expect(MouseButton.middle.name == "middle")
    }
}
