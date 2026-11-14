import Combine
import Foundation

/// Saved computers. Host records persist as JSON in `UserDefaults`; passwords
/// go to the injected `KeychainStore` so they never touch defaults or disk in
/// the clear.
final class HostStore: ObservableObject {
    @Published private(set) var hosts: [SavedHost]

    private let defaults: UserDefaults
    private let keychain: KeychainStore
    private let key: String

    init(defaults: UserDefaults = .standard,
         keychain: KeychainStore,
         key: String = "peek.hosts") {
        self.defaults = defaults
        self.keychain = keychain
        self.key = key
        self.hosts = HostStore.load(from: defaults, key: key)
    }

    /// Insert or replace a host. A non-empty `password` is stored when the host
    /// remembers passwords; turning remembering off forgets any stored one.
    func save(_ host: SavedHost, password: String?) {
        if let index = hosts.firstIndex(where: { $0.id == host.id }) {
            hosts[index] = host
        } else {
            hosts.append(host)
        }
        if host.rememberPassword {
            if let password, !password.isEmpty {
                keychain.setPassword(password, for: host.id)
            }
        } else {
            keychain.removePassword(for: host.id)
        }
        persist()
    }

    func remove(_ host: SavedHost) {
        hosts.removeAll { $0.id == host.id }
        keychain.removePassword(for: host.id)
        persist()
    }

    func remove(at offsets: IndexSet) {
        offsets.map { hosts[$0] }.forEach(remove)
    }

    /// The stored password, only when the host opted into remembering it.
    func password(for host: SavedHost) -> String? {
        host.rememberPassword ? keychain.password(for: host.id) : nil
    }

    /// Called when the user ticks "Remember password" at sign-in time.
    func rememberPassword(_ password: String, for host: SavedHost) {
        var updated = host
        updated.rememberPassword = true
        save(updated, password: password)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(hosts) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [SavedHost] {
        guard let data = defaults.data(forKey: key),
              let hosts = try? JSONDecoder().decode([SavedHost].self, from: data) else { return [] }
        return hosts
    }
}
