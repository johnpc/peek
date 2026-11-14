import Foundation

/// Everything the UI needs, assembled once at launch. `live()` wires the real
/// keychain, Bonjour and RoyalVNC; `MockMode.environment` swaps in fakes.
final class AppEnvironment {
    let hosts: HostStore
    let discovery: DiscoveryStore
    let settings: SettingsStore
    let makeDesktop: RemoteDesktopFactory

    init(hosts: HostStore,
         discovery: DiscoveryStore,
         settings: SettingsStore,
         makeDesktop: @escaping RemoteDesktopFactory) {
        self.hosts = hosts
        self.discovery = discovery
        self.settings = settings
        self.makeDesktop = makeDesktop
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            hosts: HostStore(keychain: SystemKeychain()),
            discovery: DiscoveryStore(browser: BonjourBrowser()),
            settings: SettingsStore(),
            makeDesktop: { host, options in RoyalVNCDesktop(host: host, options: options) }
        )
    }

    /// A session for `host`, pre-loaded with its remembered password and wired
    /// to store a new one when the user asks.
    func makeSession(for host: SavedHost) -> VNCSession {
        let options = settings.options
        let session = VNCSession(host: host, savedPassword: hosts.password(for: host)) { [makeDesktop] in
            makeDesktop(host, options)
        }
        session.onRememberPassword = { [hosts] password in
            hosts.rememberPassword(password, for: host)
        }
        return session
    }
}
