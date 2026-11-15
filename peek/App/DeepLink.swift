import Foundation

/// `peek://connect?host=Studio%20Mac` — open straight into a computer. `host`
/// matches a saved computer's name (case-insensitive) or address; an unknown
/// address opens the add-computer form pre-filled, so the link still helps.
enum DeepLink: Equatable {
    case connect(host: String)

    static let scheme = "peek"

    static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == "connect" else { return nil }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let host = items.first(where: { $0.name == "host" })?.value?.trimmingCharacters(in: .whitespaces),
              !host.isEmpty else { return nil }
        return .connect(host: host)
    }

    /// The URL that reopens `host`, for sharing into Shortcuts.
    static func url(for host: SavedHost) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "connect"
        components.queryItems = [URLQueryItem(name: "host", value: host.displayName)]
        return components.url
    }

    /// Saved computer the link refers to, if any: by name, Bonjour name, or
    /// address. Macs advertise names with a curly apostrophe ("john’s Mac
    /// Mini"), which nobody types, so apostrophes are normalised.
    static func match(_ query: String, in hosts: [SavedHost]) -> SavedHost? {
        let needle = normalized(query)
        return hosts.first { normalized($0.displayName) == needle || normalized($0.serviceName ?? "") == needle }
            ?? hosts.first { normalized($0.hostname) == needle || normalized($0.address) == needle }
    }

    static func normalized(_ text: String) -> String {
        text.lowercased().replacingOccurrences(of: "’", with: "'").trimmingCharacters(in: .whitespaces)
    }
}
