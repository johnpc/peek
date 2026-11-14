import Foundation
import Network

/// Browses `_rfb._tcp` (Screen Sharing / VNC) over Bonjour. Network.framework
/// exposes no standalone resolver, so each service is resolved by briefly
/// opening a TCP connection to it and reading the remote endpoint.
final class BonjourBrowser: HostBrowser {
    var onHostsChanged: (([DiscoveredHost]) -> Void)?

    private var browser: NWBrowser?
    private var resolved: [String: DiscoveredHost] = [:]
    private var resolvers: [String: NWConnection] = [:]

    func start() {
        let descriptor = NWBrowser.Descriptor.bonjour(type: BonjourEndpoint.serviceType, domain: nil)
        let browser = NWBrowser(for: descriptor, using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in self?.update(Array(results.map(\.endpoint))) }
        }
        browser.start(queue: .main)
        self.browser = browser
    }

    func stop() {
        browser?.cancel()
        browser = nil
        resolvers.values.forEach { $0.cancel() }
        resolvers = [:]
        resolved = [:]
    }

    /// Reconcile the advertised set: drop vanished services, resolve new ones.
    func update(_ endpoints: [NWEndpoint]) {
        var present: Set<String> = []
        for endpoint in endpoints {
            guard let name = BonjourEndpoint.serviceName(of: endpoint) else { continue }
            present.insert(name)
            if resolved[name] == nil, resolvers[name] == nil {
                resolve(name: name, endpoint: endpoint)
            }
        }
        resolved = resolved.filter { present.contains($0.key) }
        publish()
    }

    private func resolve(name: String, endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: BonjourEndpoint.ipv4Parameters())
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                let remote = connection.currentPath?.remoteEndpoint
                connection.cancel()
                Task { @MainActor in self?.finishResolve(name: name, endpoint: remote) }
            case .failed, .cancelled:
                Task { @MainActor in self?.finishResolve(name: name, endpoint: nil) }
            default:
                break
            }
        }
        resolvers[name] = connection
        connection.start(queue: .main)
    }

    func finishResolve(name: String, endpoint: NWEndpoint?) {
        resolvers[name] = nil
        guard let host = BonjourEndpoint.host(from: endpoint, serviceName: name) else { return }
        resolved[name] = host
        publish()
    }

    private func publish() {
        onHostsChanged?(Array(resolved.values))
    }
}
