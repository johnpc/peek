import Foundation
import Network

/// Turns a Bonjour service name back into a dialable address at connect time.
protocol HostResolver: AnyObject {
    func resolve(serviceName: String) async -> String?
}

/// Deterministic resolver for tests and mock mode.
final class MockResolver: HostResolver {
    var answers: [String: String]
    private(set) var requests: [String] = []

    init(answers: [String: String] = [:]) {
        self.answers = answers
    }

    func resolve(serviceName: String) async -> String? {
        requests.append(serviceName)
        return answers[serviceName]
    }
}

/// Opens a short-lived TCP connection to the advertised service and reads the
/// address it landed on — the same trick `BonjourBrowser` uses. Gives up after
/// `timeout` so an offline Mac falls back to the last known address.
final class BonjourResolver: HostResolver {
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 4) {
        self.timeout = timeout
    }

    func resolve(serviceName: String) async -> String? {
        let endpoint = NWEndpoint.service(name: serviceName, type: BonjourEndpoint.serviceType,
                                          domain: "local.", interface: nil)
        let connection = NWConnection(to: endpoint, using: BonjourEndpoint.ipv4Parameters())
        return await withCheckedContinuation { (continuation: CheckedContinuation<String?, Never>) in
            let finished = Finished()
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let host = BonjourEndpoint.host(from: connection.currentPath?.remoteEndpoint, serviceName: serviceName)
                    connection.cancel()
                    finished.resume(continuation, with: host?.hostname)
                case .failed, .cancelled:
                    finished.resume(continuation, with: nil)
                default:
                    break
                }
            }
            connection.start(queue: .main)
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                connection.cancel()
                finished.resume(continuation, with: nil)
            }
        }
    }

    /// Resumes a continuation at most once, whichever callback wins.
    private final class Finished: @unchecked Sendable {
        private var done = false
        func resume(_ continuation: CheckedContinuation<String?, Never>, with value: String?) {
            guard !done else { return }
            done = true
            continuation.resume(returning: value)
        }
    }
}
