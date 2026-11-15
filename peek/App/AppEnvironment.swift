import Foundation

/// Everything the UI needs, assembled once at launch. `live()` wires the real
/// keychain, Bonjour and RoyalVNC; `MockMode.environment` swaps in fakes.
final class AppEnvironment {
    let hosts: HostStore
    let discovery: DiscoveryStore
    let settings: SettingsStore
    let makeDesktop: RemoteDesktopFactory
    let resolver: HostResolver
    let pasteboard: Pasteboard
    let thumbnails: ThumbnailStore

    init(hosts: HostStore,
         discovery: DiscoveryStore,
         settings: SettingsStore,
         resolver: HostResolver,
         pasteboard: Pasteboard = SystemPasteboard(),
         thumbnails: ThumbnailStore = ThumbnailStore(),
         makeDesktop: @escaping RemoteDesktopFactory) {
        self.hosts = hosts
        self.discovery = discovery
        self.settings = settings
        self.resolver = resolver
        self.pasteboard = pasteboard
        self.thumbnails = thumbnails
        self.makeDesktop = makeDesktop
    }

    static func live() -> AppEnvironment {
        AppEnvironment(
            hosts: HostStore(keychain: SystemKeychain()),
            discovery: DiscoveryStore(browser: BonjourBrowser()),
            settings: SettingsStore(),
            resolver: BonjourResolver(),
            makeDesktop: { host, options in RoyalVNCDesktop(host: host, options: options) }
        )
    }

    /// A session for `host`, pre-loaded with its remembered password and wired
    /// to store a new one when the user asks.
    func makeSession(for host: SavedHost) -> VNCSession {
        let options = settings.options
        let session = VNCSession(host: host, savedPassword: hosts.password(for: host),
                                 resolver: resolver, pasteboard: pasteboard) { [makeDesktop] target in
            makeDesktop(target, options)
        }
        session.onRememberPassword = { [hosts] password in
            hosts.rememberPassword(password, for: host)
        }
        session.onAddressChanged = { [hosts] address in
            var updated = host
            updated.hostname = address
            hosts.save(updated, password: nil)
        }
        return session
    }
}
