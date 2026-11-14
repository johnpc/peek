import Foundation
import RoyalVNCKit

/// RoyalVNCKit delegate conformance. Every method is `nonisolated` because the
/// library calls from its own queues; each one forwards to a main-actor method.
extension RoyalVNCDesktop: VNCConnectionDelegate {
    nonisolated func connection(_ connection: VNCConnection,
                                stateDidChange connectionState: VNCConnection.ConnectionState) {
        let state = RoyalBridge.state(connectionState)
        Task { @MainActor in self.receive(.state(state)) }
    }

    nonisolated func connection(_ connection: VNCConnection,
                                credentialFor authenticationType: VNCAuthenticationType,
                                completion: @escaping (VNCCredential?) -> Void) {
        let request = CredentialRequest(needsUsername: authenticationType.requiresUsername)
        Task { @MainActor in self.receiveCredentialRequest(request, completion: completion) }
    }

    nonisolated func connection(_ connection: VNCConnection, didCreateFramebuffer framebuffer: VNCFramebuffer) {
        Task { @MainActor in self.receiveFramebuffer(framebuffer) }
    }

    nonisolated func connection(_ connection: VNCConnection, didResizeFramebuffer framebuffer: VNCFramebuffer) {
        Task { @MainActor in self.receiveFramebuffer(framebuffer) }
    }

    nonisolated func connection(_ connection: VNCConnection,
                                didUpdateFramebuffer framebuffer: VNCFramebuffer,
                                x: UInt16, y: UInt16, width: UInt16, height: UInt16) {
        Task { @MainActor in self.receive(.framebufferUpdated) }
    }

    nonisolated func connection(_ connection: VNCConnection, didUpdateCursor cursor: VNCCursor) {
        // The remote cursor isn't drawn: on a touchscreen the finger is the pointer.
    }
}
