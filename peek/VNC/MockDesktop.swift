import CoreGraphics
import Foundation

/// Stand-in desktop for unit tests and UI-test mock mode. Asks for a password
/// (unless told not to), accepts `acceptedPassword`, paints a synthetic screen
/// and records every input it receives.
final class MockDesktop: RemoteDesktop {
    var onEvent: ((RemoteDesktopEvent) -> Void)?

    var requiresCredential = true
    var needsUsername = true
    var acceptedPassword = "secret"
    var screenSize = CGSize(width: 1280, height: 800)
    static let rejectionMessage = "The password was not accepted."

    private(set) var inputs: [RemoteInput] = []
    private(set) var suppliedCredentials: [RemoteCredential?] = []
    private(set) var connectCount = 0
    private(set) var disconnectCount = 0
    private(set) var isConnected = false
    private var image: CGImage?

    func connect() {
        connectCount += 1
        emit(.state(.connecting))
        if requiresCredential {
            emit(.credentialNeeded(CredentialRequest(needsUsername: needsUsername)))
        } else {
            finishConnecting()
        }
    }

    func supply(_ credential: RemoteCredential?) {
        suppliedCredentials.append(credential)
        guard let credential else {
            emit(.state(.disconnected(nil)))
            return
        }
        if credential.password == acceptedPassword {
            finishConnecting()
        } else {
            emit(.state(.disconnected(.authentication(Self.rejectionMessage))))
        }
    }

    func disconnect() {
        disconnectCount += 1
        isConnected = false
        emit(.state(.disconnected(nil)))
    }

    func send(_ input: RemoteInput) {
        inputs.append(input)
    }

    func snapshot() -> CGImage? {
        guard isConnected else { return nil }
        if image == nil { image = MockFrame.render(size: screenSize) }
        return image
    }

    private func finishConnecting() {
        isConnected = true
        emit(.state(.connected))
        emit(.framebufferChanged(screenSize))
        emit(.framebufferUpdated)
    }

    private func emit(_ event: RemoteDesktopEvent) {
        onEvent?(event)
    }
}
