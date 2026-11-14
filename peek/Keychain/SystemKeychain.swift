import Foundation
import Security

/// The real keychain: one generic-password item per host, scoped to the app's
/// own service name so nothing collides with other apps.
final class SystemKeychain: KeychainStore {
    private let service: String

    init(service: String = "com.johncorser.peek.hosts") {
        self.service = service
    }

    func password(for id: UUID) -> String? {
        var query = baseQuery(for: id)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func setPassword(_ password: String, for id: UUID) {
        removePassword(for: id)
        var item = baseQuery(for: id)
        item[kSecValueData as String] = Data(password.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(item as CFDictionary, nil)
    }

    func removePassword(for id: UUID) {
        SecItemDelete(baseQuery(for: id) as CFDictionary)
    }

    private func baseQuery(for id: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
        ]
    }
}
