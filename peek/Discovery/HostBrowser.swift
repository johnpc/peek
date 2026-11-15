import Foundation

/// Why the Nearby list might be empty.
enum DiscoveryStatus: Equatable {
    case searching
    /// iOS's Local Network permission was declined (or is restricted).
    case localNetworkDenied
    case failed(String)
}

/// Source of nearby Screen Sharing / VNC servers. `BonjourBrowser` is the real
/// one; `MockBrowser` feeds fixtures to tests. Deliver callbacks on the main actor.
protocol HostBrowser: AnyObject {
    var onHostsChanged: (([DiscoveredHost]) -> Void)? { get set }
    var onStatusChanged: ((DiscoveryStatus) -> Void)? { get set }
    func start()
    func stop()
}

/// Deterministic browser for tests and UI-test mock mode.
final class MockBrowser: HostBrowser {
    var onHostsChanged: (([DiscoveredHost]) -> Void)?
    var onStatusChanged: ((DiscoveryStatus) -> Void)?
    var fixtures: [DiscoveredHost]
    var status: DiscoveryStatus
    private(set) var isRunning = false

    init(fixtures: [DiscoveredHost], status: DiscoveryStatus = .searching) {
        self.fixtures = fixtures
        self.status = status
    }

    func start() {
        isRunning = true
        onStatusChanged?(status)
        onHostsChanged?(status == .searching ? fixtures : [])
    }

    func stop() {
        isRunning = false
    }
}
