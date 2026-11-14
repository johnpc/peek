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

    var trimmedHostname: String {
        hostname.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool {
        !trimmedHostname.isEmpty && port != nil
    }

    /// The host to save, or nil while the form is invalid.
    func makeHost() -> SavedHost? {
        guard isValid, let port else { return nil }
        return SavedHost(id: id,
                         name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                         hostname: trimmedHostname,
                         port: port,
                         username: username.trimmingCharacters(in: .whitespaces),
                         rememberPassword: rememberPassword)
    }
}
