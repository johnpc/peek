import Foundation

/// Why a connection ended (or never started). Messages are user-facing.
enum RemoteFailure: Equatable {
    case authentication(String)
    case connection(String)

    var message: String {
        switch self {
        case .authentication(let text), .connection(let text):
            return text
        }
    }

    var isAuthentication: Bool {
        if case .authentication = self { return true }
        return false
    }
}

/// Lifecycle of one remote-desktop connection.
enum RemoteState: Equatable {
    case idle
    case connecting
    case connected
    case disconnected(RemoteFailure?)

    var isActive: Bool {
        switch self {
        case .connecting, .connected: return true
        case .idle, .disconnected: return false
        }
    }

    var failure: RemoteFailure? {
        if case .disconnected(let failure) = self { return failure }
        return nil
    }

    /// Short status line for the session toolbar.
    var label: String {
        switch self {
        case .idle: return "Not connected"
        case .connecting: return "Connecting…"
        case .connected: return "Connected"
        case .disconnected(nil): return "Disconnected"
        case .disconnected(.some(let failure)): return failure.message
        }
    }
}
