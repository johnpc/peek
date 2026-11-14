import Foundation

/// Pure helpers for the Nearby section.
enum DiscoveryLogic {
    /// One entry per service name, A→Z, case-insensitive.
    static func sorted(_ hosts: [DiscoveredHost]) -> [DiscoveredHost] {
        var seen: Set<String> = []
        let unique = hosts.filter { seen.insert($0.serviceName).inserted }
        return unique.sorted {
            $0.serviceName.localizedCaseInsensitiveCompare($1.serviceName) == .orderedAscending
        }
    }

    /// Hide nearby entries the user already saved, matched by address or by
    /// the exact name they kept from the advertisement.
    static func excludingSaved(_ nearby: [DiscoveredHost], saved: [SavedHost]) -> [DiscoveredHost] {
        nearby.filter { candidate in
            !saved.contains { host in
                (host.hostname == candidate.hostname && host.port == candidate.port)
                    || host.name == candidate.serviceName
            }
        }
    }
}
