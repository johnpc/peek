import Foundation
import Testing
@testable import peek

struct MockModeTests {
    @Test func detectsLaunchArgument() {
        #expect(MockMode.isEnabled(["--uitest-mock"]))
        #expect(!MockMode.isEnabled([]))
    }

    @Test func seedsFixtureHostWithoutPassword() {
        let env = MockMode.environment(["--uitest-mock"])
        #expect(env.hosts.hosts.map(\.name) == ["Studio Mac"])
        #expect(env.hosts.password(for: env.hosts.hosts[0]) == nil)
        env.discovery.start()
        #expect(env.discovery.nearby == [MockMode.fixtureNearby])
    }

    @Test func seedsSavedPasswordOnRequest() {
        let env = MockMode.environment(["--uitest-mock", "--uitest-saved-password"])
        #expect(env.hosts.password(for: env.hosts.hosts[0]) == MockMode.fixturePassword)
        let session = env.makeSession(for: env.hosts.hosts[0])
        session.connect()
        #expect(session.state == .connected)
    }

    @Test func noLocalNetworkFlagReportsDenied() {
        let env = MockMode.environment(["--uitest-mock", "--uitest-no-local-network"])
        env.discovery.start()
        #expect(env.discovery.status == .localNetworkDenied)
        #expect(env.discovery.nearby.isEmpty)
    }

    @Test func pasteboardFlagPreloadsTheMockClipboard() {
        let env = MockMode.environment(["--uitest-mock", "--uitest-pasteboard"])
        #expect(env.pasteboard.string == MockMode.fixturePasteboardText)
        #expect(MockMode.environment(["--uitest-mock"]).pasteboard.string == nil)
    }

    @Test func noHostsFlagStartsEmpty() {
        let env = MockMode.environment(["--uitest-mock", "--uitest-no-hosts"])
        #expect(env.hosts.hosts.isEmpty)
    }
}

struct AppEnvironmentTests {
    @Test func liveEnvironmentWiresRealDesktop() {
        let env = AppEnvironment.live()
        #expect(env.resolver is BonjourResolver)
        let desktop = env.makeDesktop(SavedHost(name: "x", hostname: "127.0.0.1", port: 1), env.settings.options)
        #expect(desktop is RoyalVNCDesktop)
    }

    @Test func sessionRemembersPasswordThroughTheStore() {
        let env = MockMode.environment(["--uitest-mock"])
        let host = env.hosts.hosts[0]
        let session = env.makeSession(for: host)
        session.connect()
        session.submitCredential(username: "john", password: "secret", remember: true)
        #expect(env.hosts.password(for: env.hosts.hosts[0]) == "secret")
        #expect(env.hosts.hosts[0].rememberPassword)
    }
}

struct HostDraftTests {
    @Test func newDraftIsInvalidUntilHostnameTyped() {
        var draft = HostDraft()
        #expect(draft.isNew)
        #expect(draft.title == "Add Computer")
        #expect(!draft.isValid)
        draft.hostname = "  mac.local "
        #expect(draft.isValid)
        #expect(draft.makeHost()?.hostname == "mac.local")
        #expect(draft.makeHost()?.port == 5900)
    }

    @Test func portValidation() {
        var draft = HostDraft(host: SavedHost(name: "A", hostname: "a"))
        #expect(!draft.isNew)
        #expect(draft.title == "Edit Computer")
        draft.portText = "abc"
        #expect(draft.port == nil)
        #expect(draft.makeHost() == nil)
        draft.portText = "70000"
        #expect(draft.port == nil)
        draft.portText = " 5901 "
        #expect(draft.port == 5901)
    }

    @Test func hostnameMayCarryAPort() {
        var draft = HostDraft()
        draft.hostname = "mac.local:5901"
        #expect(draft.trimmedHostname == "mac.local")
        #expect(draft.effectivePort == 5901)
        #expect(draft.makeHost()?.address == "mac.local:5901")
        draft.hostname = "fe80::1"
        #expect(draft.trimmedHostname == "fe80::1")
        #expect(draft.effectivePort == 5900)
        draft.hostname = "mac.local:notaport"
        #expect(draft.trimmedHostname == "mac.local:notaport")
        #expect(HostDraft.split("mac.local:0").port == nil)
    }

    @Test func keepsIdentityAndTrimsFields() {
        let original = SavedHost(name: "A", hostname: "a", username: "john", rememberPassword: true)
        var draft = HostDraft(host: original)
        draft.name = " B "
        draft.username = " jane "
        let host = draft.makeHost()
        #expect(host?.id == original.id)
        #expect(host?.name == "B")
        #expect(host?.username == "jane")
        #expect(host?.rememberPassword == true)
    }
}

struct DeepLinkTests {
    @Test func parsesConnectLinks() {
        #expect(DeepLink.parse(URL(string: "peek://connect?host=Studio%20Mac")!) == .connect(host: "Studio Mac"))
        #expect(DeepLink.parse(URL(string: "PEEK://Connect?host=mini")!) == .connect(host: "mini"))
        #expect(DeepLink.parse(URL(string: "peek://connect")!) == nil)
        #expect(DeepLink.parse(URL(string: "peek://connect?host=%20")!) == nil)
        #expect(DeepLink.parse(URL(string: "peek://other?host=x")!) == nil)
        #expect(DeepLink.parse(URL(string: "https://connect?host=x")!) == nil)
    }

    @Test func buildsAndMatches() {
        let studio = SavedHost(name: "Studio Mac", hostname: "studio.local")
        let bare = SavedHost(name: "", hostname: "10.0.0.5", port: 5901)
        let url = DeepLink.url(for: studio)
        #expect(url?.absoluteString == "peek://connect?host=Studio%20Mac")
        #expect(DeepLink.parse(url!) == .connect(host: "Studio Mac"))
        #expect(DeepLink.match("studio mac", in: [studio, bare]) == studio)
        #expect(DeepLink.match("STUDIO.LOCAL", in: [studio, bare]) == studio)
        #expect(DeepLink.match("10.0.0.5:5901", in: [studio, bare]) == bare)
        #expect(DeepLink.match("nope", in: [studio, bare]) == nil)
        let mini = SavedHost(name: "john’s Mac Mini", hostname: "fe80::1%en0", serviceName: "john’s Mac Mini")
        #expect(DeepLink.match("John's Mac Mini", in: [mini]) == mini, "straight apostrophe matches the curly one")
        #expect(DeepLink.match("john’s mac mini", in: [mini]) == mini)
        let renamed = SavedHost(name: "Office", hostname: "10.0.0.9", serviceName: "john’s Mac Mini")
        #expect(DeepLink.match("john's mac mini", in: [renamed]) == renamed, "Bonjour name still matches after a rename")
    }
}

struct HostListModelTests {
    @Test func deepLinksConnectOrPrefillTheForm() {
        let env = MockMode.environment(["--uitest-mock", "--uitest-saved-password"])
        let model = HostListModel(environment: env)
        model.open(URL(string: "peek://connect?host=studio%20mac")!)
        #expect(model.session?.host.name == "Studio Mac")
        model.closeSession()
        model.open(URL(string: "peek://connect?host=office.local:5901")!)
        #expect(model.session == nil)
        #expect(model.draft?.hostname == "office.local")
        #expect(model.draft?.portText == "5901")
        #expect(model.draft?.isNew == true)
        model.draft = nil
        model.open(URL(string: "https://example.com")!)
        #expect(model.draft == nil && model.session == nil)
    }

    @Test func sheetsAndSessions() {
        let env = MockMode.environment(["--uitest-mock"])
        let model = HostListModel(environment: env)
        model.addHost()
        #expect(model.draft?.isNew == true)
        model.edit(env.hosts.hosts[0])
        #expect(model.draft?.isNew == false)
        model.add(MockMode.fixtureNearby)
        #expect(model.draft?.hostname == "johns-mac-mini.local")
        #expect(model.draft?.isNew == true)

        if var draft = model.draft {
            draft.name = "Mini"
            model.save(draft)
        }
        #expect(model.draft == nil)
        #expect(env.hosts.hosts.map(\.name) == ["Studio Mac", "Mini"])
        model.save(HostDraft())
        #expect(env.hosts.hosts.count == 2, "invalid drafts are not saved")

        model.connect(env.hosts.hosts[0])
        #expect(model.session?.host.name == "Studio Mac")
        model.session?.connect()
        model.session?.submitCredential(username: "john", password: "secret", remember: false)
        model.session?.refreshFrame()  // the live throttle flushes asynchronously
        #expect(model.session?.frame != nil)
        model.closeSession()
        #expect(model.session == nil)
        #expect(env.thumbnails.image(for: env.hosts.hosts[0].id) != nil, "hanging up keeps a thumbnail")

        let studioId = env.hosts.hosts[0].id
        model.delete(env.hosts.hosts[1])
        #expect(env.hosts.hosts.map(\.name) == ["Studio Mac"])
        model.delete(env.hosts.hosts[0])
        #expect(env.thumbnails.image(for: studioId) == nil, "deleting a host drops its thumbnail")
        #expect(model.nearby([MockMode.fixtureNearby], saved: env.hosts.hosts) == [MockMode.fixtureNearby])
    }
}
