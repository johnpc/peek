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

    @Test func noHostsFlagStartsEmpty() {
        let env = MockMode.environment(["--uitest-mock", "--uitest-no-hosts"])
        #expect(env.hosts.hosts.isEmpty)
    }
}

struct AppEnvironmentTests {
    @Test func liveEnvironmentWiresRealDesktop() {
        let env = AppEnvironment.live()
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

struct HostListModelTests {
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
        model.closeSession()
        #expect(model.session == nil)

        model.delete(env.hosts.hosts[1])
        #expect(env.hosts.hosts.map(\.name) == ["Studio Mac"])
        #expect(model.nearby([MockMode.fixtureNearby], saved: env.hosts.hosts) == [MockMode.fixtureNearby])
    }
}
