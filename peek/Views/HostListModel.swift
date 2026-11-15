import Combine
import Foundation

/// Presentation state for the computer list: which sheet is up and which
/// session is live. Views bind to it; the stores do the persistence.
final class HostListModel: ObservableObject {
    @Published var draft: HostDraft?
    @Published var session: VNCSession?
    @Published var showSettings = false

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func addHost() {
        draft = HostDraft()
    }

    func edit(_ host: SavedHost) {
        draft = HostDraft(host: host)
    }

    /// Pre-fill the form from a Bonjour advertisement.
    func add(_ nearby: DiscoveredHost) {
        draft = HostDraft(host: nearby.asSavedHost())
        draft?.isNew = true
    }

    func save(_ draft: HostDraft) {
        guard let host = draft.makeHost() else { return }
        environment.hosts.save(host, password: draft.password)
        self.draft = nil
    }

    func delete(_ host: SavedHost) {
        environment.hosts.remove(host)
        environment.thumbnails.remove(for: host.id)
    }

    func connect(_ host: SavedHost) {
        session = environment.makeSession(for: host)
    }

    /// Hanging up also keeps the last frame as the host's thumbnail.
    func closeSession() {
        if let session, let frame = session.frame {
            environment.thumbnails.save(frame, for: session.host.id)
        }
        session?.disconnect()
        session = nil
    }

    /// A `peek://` link: connect to the matching computer, or offer to add it.
    func open(_ url: URL) {
        guard case .connect(let query)? = DeepLink.parse(url) else { return }
        if let host = DeepLink.match(query, in: environment.hosts.hosts) {
            session = nil
            connect(host)
        } else {
            let split = HostDraft.split(query)
            var draft = HostDraft(host: SavedHost(name: "", hostname: split.host, port: split.port ?? SavedHost.defaultPort))
            draft.isNew = true
            self.draft = draft
        }
    }

    /// Nearby computers not already in the saved list.
    func nearby(_ discovered: [DiscoveredHost], saved: [SavedHost]) -> [DiscoveredHost] {
        DiscoveryLogic.excludingSaved(discovered, saved: saved)
    }
}
