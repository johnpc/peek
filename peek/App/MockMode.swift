import Foundation

/// Launch arguments that put the app into a hermetic mock mode for UI tests:
/// fixture hosts, an in-memory keychain, a fake Bonjour browser and a fake
/// desktop that paints its own screen. The UI-test bundle hardcodes the same
/// strings (it can't link the app).
enum MockMode {
    static let launchArgument = "--uitest-mock"
    /// Seed the keychain with the fixture host's password (connects without asking).
    static let savedPasswordArgument = "--uitest-saved-password"
    /// Start with no saved hosts (empty state).
    static let noHostsArgument = "--uitest-no-hosts"
    /// Pretend iOS declined Local Network access.
    static let noLocalNetworkArgument = "--uitest-no-local-network"

    static let fixtureHost = SavedHost(name: "Studio Mac", hostname: "studio.local", username: "john")
    static let fixturePassword = "secret"
    static let fixtureNearby = DiscoveredHost(serviceName: "John's Mac mini",
                                              hostname: "johns-mac-mini.local",
                                              port: SavedHost.defaultPort)

    static func isEnabled(_ args: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        args.contains(launchArgument)
    }

    /// A fully wired environment for the given launch arguments. Uses a scratch
    /// defaults suite that is wiped on every launch so scenarios stay isolated.
    static func environment(_ args: [String] = ProcessInfo.processInfo.arguments) -> AppEnvironment {
        let suite = "peek.uitest"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let keychain = InMemoryKeychain()
        let hosts = HostStore(defaults: defaults, keychain: keychain)
        if !args.contains(noHostsArgument) {
            var host = fixtureHost
            host.rememberPassword = args.contains(savedPasswordArgument)
            hosts.save(host, password: host.rememberPassword ? fixturePassword : nil)
        }
        return AppEnvironment(
            hosts: hosts,
            discovery: DiscoveryStore(browser: MockBrowser(
                fixtures: [fixtureNearby],
                status: args.contains(noLocalNetworkArgument) ? .localNetworkDenied : .searching)),
            settings: SettingsStore(defaults: defaults),
            makeDesktop: { _, _ in MockDesktop() }
        )
    }
}
