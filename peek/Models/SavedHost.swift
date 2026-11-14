import Foundation

/// A remembered remote computer. Passwords never live on this value — they are
/// kept in the keychain under `id` (see `KeychainStore`), so hosts can be
/// persisted as plain JSON in `UserDefaults`.
struct SavedHost: Identifiable, Codable, Equatable, Hashable {
    static let defaultPort: UInt16 = 5900

    var id: UUID
    var name: String
    var hostname: String
    var port: UInt16
    /// macOS account name. Required by Apple Remote Desktop authentication
    /// (what Screen Sharing uses); ignored by plain VNC-password servers.
    var username: String
    var rememberPassword: Bool

    init(id: UUID = UUID(),
         name: String,
         hostname: String,
         port: UInt16 = SavedHost.defaultPort,
         username: String = "",
         rememberPassword: Bool = false) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.port = port
        self.username = username
        self.rememberPassword = rememberPassword
    }

    /// What the list shows under the name: the host, plus the port when non-default.
    var address: String {
        port == Self.defaultPort ? hostname : "\(hostname):\(port)"
    }

    /// Falls back to the hostname when the user left the name blank.
    var displayName: String {
        name.isEmpty ? hostname : name
    }
}
