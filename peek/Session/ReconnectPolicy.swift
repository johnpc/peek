import Foundation

/// When the app returns to the foreground after iOS suspended its sockets,
/// decide whether to silently reconnect. Authentication failures and
/// deliberate disconnects are left alone; dropped connections come back.
enum ReconnectPolicy {
    static func shouldReconnect(after state: RemoteState, userDisconnected: Bool) -> Bool {
        guard !userDisconnected, case .disconnected(let failure) = state else { return false }
        return failure.map { !$0.isAuthentication } ?? false
    }
}
