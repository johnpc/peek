import Combine
import Foundation

/// Publishes the current set of nearby computers from a `HostBrowser`.
final class DiscoveryStore: ObservableObject {
    @Published private(set) var nearby: [DiscoveredHost] = []

    private let browser: HostBrowser

    init(browser: HostBrowser) {
        self.browser = browser
        browser.onHostsChanged = { [weak self] hosts in
            self?.nearby = DiscoveryLogic.sorted(hosts)
        }
    }

    func start() {
        browser.start()
    }

    func stop() {
        browser.stop()
        nearby = []
    }
}
