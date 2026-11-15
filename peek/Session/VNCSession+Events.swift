import CoreGraphics
import Foundation

/// Desktop events → published state.
extension VNCSession {
    func handle(_ event: RemoteDesktopEvent) {
        switch event {
        case .state(let next):
            state = next
            if next == .connected {
                notePasteboardBaseline()
                didConnect()
            }
        case .credentialNeeded(let request):
            if request.needsUsername { modifiers.keymap = .appleRemoteDesktop }
            if let password = savedPassword, !triedSavedPassword {
                triedSavedPassword = true
                desktop?.supply(RemoteCredential(username: host.username, password: password))
            } else {
                credentialRequest = request
            }
        case .framebufferChanged(let size):
            if size != screenSize { pointer.reset(to: size) }
            screenSize = size
            throttle.markDirty()
        case .framebufferUpdated:
            throttle.markDirty()
        case .cursorChanged(let cursor):
            self.cursor = cursor
        }
    }

    func didConnect() {
        if let password = submittedPassword {
            savedPassword = password
            submittedPassword = nil
        }
        if let password = pendingRemember {
            pendingRemember = nil
            onRememberPassword?(password)
        }
    }

    func refreshFrame() {
        frame = desktop?.snapshot()
    }
}
