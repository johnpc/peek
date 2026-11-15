import Foundation
import Network
import Testing
@testable import peek

struct DiscoveryLogicTests {
    private let mini = DiscoveredHost(serviceName: "mini", hostname: "10.0.0.2", port: 5900)
    private let air = DiscoveredHost(serviceName: "Air", hostname: "10.0.0.3", port: 5900)

    @Test func sortsCaseInsensitivelyAndDedupes() {
        let sorted = DiscoveryLogic.sorted([mini, air, mini])
        #expect(sorted == [air, mini])
    }

    @Test func excludesSavedByAddressOrName() {
        let byAddress = SavedHost(name: "Other", hostname: "10.0.0.2")
        let byName = SavedHost(name: "Air", hostname: "elsewhere")
        #expect(DiscoveryLogic.excludingSaved([mini, air], saved: [byAddress]) == [air])
        #expect(DiscoveryLogic.excludingSaved([mini, air], saved: [byName]) == [mini])
        #expect(DiscoveryLogic.excludingSaved([mini], saved: [SavedHost(name: "X", hostname: "10.0.0.2", port: 5901)]) == [mini])
    }
}

struct DiscoveryStoreTests {
    @Test func publishesSortedFixturesAndClearsOnStop() {
        let browser = MockBrowser(fixtures: [
            DiscoveredHost(serviceName: "b", hostname: "2", port: 1),
            DiscoveredHost(serviceName: "A", hostname: "1", port: 1),
        ])
        let store = DiscoveryStore(browser: browser)
        store.start()
        #expect(browser.isRunning)
        #expect(store.nearby.map(\.serviceName) == ["A", "b"])
        store.stop()
        #expect(!browser.isRunning)
        #expect(store.nearby.isEmpty)
        #expect(store.status == .searching)
    }

    @Test func deniedLocalNetworkHidesFixturesAndReportsStatus() {
        let browser = MockBrowser(fixtures: [DiscoveredHost(serviceName: "a", hostname: "1", port: 1)], status: .localNetworkDenied)
        let store = DiscoveryStore(browser: browser)
        store.start()
        #expect(store.status == .localNetworkDenied)
        #expect(store.nearby.isEmpty)
    }
}

struct BonjourEndpointTests {
    @Test func mapsHostPortEndpoints() {
        let endpoint = NWEndpoint.hostPort(host: .ipv4(.loopback), port: 5900)
        let host = BonjourEndpoint.host(from: endpoint, serviceName: "Mini")
        #expect(host == DiscoveredHost(serviceName: "Mini", hostname: "127.0.0.1", port: 5900))
        #expect(BonjourEndpoint.host(from: nil, serviceName: "Mini") == nil)
        let service = NWEndpoint.service(name: "Mini", type: "_rfb._tcp", domain: "local.", interface: nil)
        #expect(BonjourEndpoint.host(from: service, serviceName: "Mini") == nil)
    }

    @Test func hostStrings() {
        #expect(BonjourEndpoint.string(for: .name("mini.local", nil)) == "mini.local")
        #expect(BonjourEndpoint.string(for: .ipv6(.loopback)) == "::1")
        if let scoped = IPv6Address("fe80::1%en0") {
            #expect(BonjourEndpoint.string(for: .ipv6(scoped)).hasPrefix("fe80::1"), "scope is kept, not stripped")
        }
        #expect(BonjourEndpoint.string(for: .ipv4(.loopback)) == "127.0.0.1")
    }

    @Test func browserStatesMapToStatuses() {
        #expect(BonjourEndpoint.status(for: .ready) == .searching)
        #expect(BonjourEndpoint.status(for: .setup) == .searching)
        #expect(BonjourEndpoint.status(for: .failed(.dns(-65570))) == .localNetworkDenied)
        #expect(BonjourEndpoint.status(for: .waiting(.dns(-65570))) == .localNetworkDenied)
        #expect(BonjourEndpoint.status(for: .failed(.posix(.ECONNREFUSED))) == .failed(NWError.posix(.ECONNREFUSED).localizedDescription))
    }

    @Test func serviceNameAndParameters() {
        let service = NWEndpoint.service(name: "Mini", type: "_rfb._tcp", domain: "local.", interface: nil)
        #expect(BonjourEndpoint.serviceName(of: service) == "Mini")
        #expect(BonjourEndpoint.serviceName(of: .hostPort(host: .ipv4(.loopback), port: 1)) == nil)
        let ip = BonjourEndpoint.ipv4Parameters().defaultProtocolStack.internetProtocol as? NWProtocolIP.Options
        #expect(ip?.version == .v4)
    }
}

struct BonjourBrowserTests {
    @Test func updateTracksServicesAndResolution() {
        let browser = BonjourBrowser()
        var published: [[DiscoveredHost]] = []
        browser.onHostsChanged = { published.append($0) }
        let service = NWEndpoint.service(name: "Mini", type: "_rfb._tcp", domain: "local.", interface: nil)
        browser.update([service, .hostPort(host: .ipv4(.loopback), port: 1)])
        #expect(published.last == [])
        browser.finishResolve(name: "Mini", endpoint: .hostPort(host: .ipv4(.loopback), port: 5900))
        #expect(published.last?.map(\.hostname) == ["127.0.0.1"])
        browser.finishResolve(name: "Ghost", endpoint: nil)
        browser.update([])
        #expect(published.last == [])
        browser.stop()
    }

    @Test func startAndStopDoNotCrash() async throws {
        let browser = BonjourBrowser()
        browser.start()
        try await Task.sleep(for: .milliseconds(200))
        browser.stop()
    }
}
