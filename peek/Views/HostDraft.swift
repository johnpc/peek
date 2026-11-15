import Foundation

/// Editable copy of a host for the add/edit form, with validation.
struct HostDraft: Equatable, Identifiable {
    var id: UUID
    var name: String
    var hostname: String
    var portText: String
    var username: String
    var password: String
    var rememberPassword: Bool
    var isNew: Bool

    init(host: SavedHost? = nil) {
        let base = host ?? SavedHost(name: "", hostname: "")
        id = base.id
        name = base.name
        hostname = base.hostname
        portText = String(base.port)
        username = base.username
        password = ""
        rememberPassword = base.rememberPassword
        isNew = host == nil
    }

    var title: String { isNew ? "Add Computer" : "Edit Computer" }

    /// A port typed by the user, or nil if it isn't a valid TCP port.
    var port: UInt16? {
        let trimmed = portText.trimmingCharacters(in: .whitespaces)
        guard let value = Int(trimmed), (1...65535).contains(value) else { return nil }
        return UInt16(value)
    }

    /// Hostname with whitespace and any `:port` suffix removed.
    var trimmedHostname: String {
        HostDraft.split(hostname).host
    }

    /// Port typed into the hostname as `host:port` wins over the port field.
    var effectivePort: UInt16? {
        HostDraft.split(hostname).port ?? port
    }

    var isValid: Bool {
        !trimmedHostname.isEmpty && effectivePort != nil
    }

    /// The host to save, or nil while the form is invalid.
    func makeHost() -> SavedHost? {
        guard isValid, let port = effectivePort else { return nil }
        return SavedHost(id: id,
                         name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                         hostname: trimmedHostname,
                         port: port,
                         username: username.trimmingCharacters(in: .whitespaces),
                         rememberPassword: rememberPassword)
    }

    /// "mac.local:5901" → ("mac.local", 5901); bare IPv6 and plain names pass through.
    static func split(_ text: String) -> (host: String, port: UInt16?) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2, let value = Int(parts[1]), (1...65535).contains(value) else {
            return (trimmed, nil)
        }
        return (String(parts[0]), UInt16(value))
    }
}
