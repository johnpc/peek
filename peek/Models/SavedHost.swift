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
    /// Bonjour service name when the host came from Nearby. Re-resolved at
    /// connect time so a new DHCP lease or IPv6 address doesn't strand the entry.
    var serviceName: String?

    init(id: UUID = UUID(),
         name: String,
         hostname: String,
         port: UInt16 = SavedHost.defaultPort,
         username: String = "",
         rememberPassword: Bool = false,
         serviceName: String? = nil) {
        self.id = id
        self.name = name
        self.hostname = hostname
        self.port = port
        self.username = username
        self.rememberPassword = rememberPassword
        self.serviceName = serviceName
    }

    /// The host, plus the port when non-default.
    var address: String {
        port == Self.defaultPort ? hostname : "\(hostname):\(port)"
    }

    /// What the list shows under the name: a Nearby host is identified by how
    /// it was found rather than by a raw (often IPv6) address.
    var subtitle: String {
        serviceName == nil ? address : "Nearby · \(address)"
    }

    /// Falls back to the hostname when the user left the name blank.
    var displayName: String {
        name.isEmpty ? hostname : name
    }
}
