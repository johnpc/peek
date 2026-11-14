import Foundation
import RoyalVNCKit

/// Pure translations between the app's remote types and RoyalVNCKit's.
nonisolated enum RoyalBridge {
    static func settings(host: SavedHost, options: DesktopOptions) -> VNCConnection.Settings {
        VNCConnection.Settings(isDebugLoggingEnabled: false,
                               hostname: host.hostname,
                               port: host.port,
                               isShared: options.isShared,
                               isScalingEnabled: options.isScalingEnabled,
                               useDisplayLink: false,
                               inputMode: .forwardKeyboardShortcutsEvenIfInUseLocally,
                               isClipboardRedirectionEnabled: true,
                               colorDepth: colorDepth(options.colorDepth),
                               frameEncodings: .default)
    }

    static func colorDepth(_ bits: Int) -> VNCConnection.Settings.ColorDepth {
        switch bits {
        case 8: return .depth8Bit
        case 16: return .depth16Bit
        default: return .depth24Bit
        }
    }

    static func state(_ connectionState: VNCConnection.ConnectionState) -> RemoteState {
        switch connectionState.status {
        case .connecting: return .connecting
        case .connected, .disconnecting: return .connected
        case .disconnected: return .disconnected(failure(connectionState.error))
        @unknown default: return .disconnected(failure(connectionState.error))
        }
    }

    static func failure(_ error: Error?) -> RemoteFailure? {
        guard let error else { return nil }
        guard let vncError = error as? VNCError else { return .connection(error.localizedDescription) }
        let text = vncError.errorDescription ?? "The connection failed."
        return vncError.isAuthenticationError ? .authentication(text) : .connection(text)
    }

    static func credential(_ credential: RemoteCredential, for request: CredentialRequest) -> VNCCredential {
        if request.needsUsername {
            return VNCUsernamePasswordCredential(username: credential.username, password: credential.password)
        }
        return VNCPasswordCredential(password: credential.password)
    }

    static func button(_ button: MouseButton) -> VNCMouseButton {
        switch button {
        case .left: return .left
        case .middle: return .middle
        case .right: return .right
        }
    }

    static func coordinate(_ value: Int) -> UInt16 {
        UInt16(clamping: max(0, value))
    }
}
