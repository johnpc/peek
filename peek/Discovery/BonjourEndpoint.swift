import Network

/// Pure mapping from a resolved Network.framework endpoint to a host record.
enum BonjourEndpoint {
    static let serviceType = "_rfb._tcp"

    static func host(from endpoint: NWEndpoint?, serviceName: String) -> DiscoveredHost? {
        guard case .hostPort(let host, let port)? = endpoint else { return nil }
        return DiscoveredHost(serviceName: serviceName, hostname: string(for: host), port: port.rawValue)
    }

    /// Hostname text a VNC library can dial: names as-is, IPv4 dotted, IPv6
    /// without the `%interface` scope suffix.
    static func string(for host: NWEndpoint.Host) -> String {
        switch host {
        case .name(let name, _):
            return name
        case .ipv4(let address):
            return "\(address)"
        case .ipv6(let address):
            return "\(address)".split(separator: "%").first.map(String.init) ?? "\(address)"
        @unknown default:
            return "\(host)"
        }
    }

    /// The advertised service name from a browse result, if it is a Bonjour service.
    static func serviceName(of endpoint: NWEndpoint) -> String? {
        guard case .service(let name, _, _, _) = endpoint else { return nil }
        return name
    }

    /// TCP pinned to IPv4 so the address we learn is a plain dotted quad.
    static func ipv4Parameters() -> NWParameters {
        let parameters = NWParameters.tcp
        if let ip = parameters.defaultProtocolStack.internetProtocol as? NWProtocolIP.Options {
            ip.version = .v4
        }
        return parameters
    }
}
