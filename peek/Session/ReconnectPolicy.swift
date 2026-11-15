import Foundation

/// When the app returns to the foreground after iOS suspended its sockets,
/// decide whether to silently reconnect. Authentication failures and
/// deliberate disconnects are left alone; dropped connections come back, and
/// a connection that sat in the background long enough for iOS to have killed
/// the socket is refreshed even if the library hasn't noticed yet.
enum ReconnectPolicy {
    /// Longer than this in the background and the TCP socket is assumed dead.
    static let staleAfter: TimeInterval = 20

    static func shouldReconnect(after state: RemoteState, userDisconnected: Bool) -> Bool {
        guard !userDisconnected, case .disconnected(let failure) = state else { return false }
        return failure.map { !$0.isAuthentication } ?? false
    }

    static func shouldRefresh(state: RemoteState, backgroundedAt: Date?, now: Date = Date()) -> Bool {
        guard state == .connected, let backgroundedAt else { return false }
        return now.timeIntervalSince(backgroundedAt) >= staleAfter
    }
}
