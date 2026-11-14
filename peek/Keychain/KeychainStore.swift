import Foundation

/// Where host passwords live. Keyed by the host's id so a password can be
/// forgotten independently of the host record.
protocol KeychainStore: AnyObject {
    func password(for id: UUID) -> String?
    func setPassword(_ password: String, for id: UUID)
    func removePassword(for id: UUID)
}

/// Test and mock-mode keychain: nothing leaves the process.
final class InMemoryKeychain: KeychainStore {
    private(set) var items: [UUID: String] = [:]

    init(items: [UUID: String] = [:]) {
        self.items = items
    }

    func password(for id: UUID) -> String? {
        items[id]
    }

    func setPassword(_ password: String, for id: UUID) {
        items[id] = password
    }

    func removePassword(for id: UUID) {
        items[id] = nil
    }
}
