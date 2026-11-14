import Foundation

/// Source of nearby Screen Sharing / VNC servers. `BonjourBrowser` is the real
/// one; `MockBrowser` feeds fixtures to tests. Deliver `onHostsChanged` on the
/// main actor.
protocol HostBrowser: AnyObject {
    var onHostsChanged: (([DiscoveredHost]) -> Void)? { get set }
    func start()
    func stop()
}

/// Deterministic browser for tests and UI-test mock mode.
final class MockBrowser: HostBrowser {
    var onHostsChanged: (([DiscoveredHost]) -> Void)?
    var fixtures: [DiscoveredHost]
    private(set) var isRunning = false

    init(fixtures: [DiscoveredHost]) {
        self.fixtures = fixtures
    }

    func start() {
        isRunning = true
        onHostsChanged?(fixtures)
    }

    func stop() {
        isRunning = false
    }
}
