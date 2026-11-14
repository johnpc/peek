import Foundation

/// A Screen Sharing / VNC server found on the local network via Bonjour.
struct DiscoveredHost: Identifiable, Equatable, Hashable {
    /// The advertised service name, e.g. "John's Mac mini".
    var serviceName: String
    /// Resolved address to connect to (an IPv4 address or `.local` name).
    var hostname: String
    var port: UInt16

    var id: String { serviceName }

    /// A saved-host value pre-filled from the advertisement.
    func asSavedHost() -> SavedHost {
        SavedHost(name: serviceName, hostname: hostname, port: port)
    }
}
