import Combine
import Foundation

/// Publishes the current set of nearby computers from a `HostBrowser`.
final class DiscoveryStore: ObservableObject {
    @Published private(set) var nearby: [DiscoveredHost] = []
    @Published private(set) var status: DiscoveryStatus = .searching

    private let browser: HostBrowser

    init(browser: HostBrowser) {
        self.browser = browser
        browser.onHostsChanged = { [weak self] hosts in
            self?.nearby = DiscoveryLogic.sorted(hosts)
        }
        browser.onStatusChanged = { [weak self] status in
            self?.status = status
        }
    }

    func start() {
        browser.start()
    }

    func stop() {
        browser.stop()
        nearby = []
        status = .searching
    }
}
