import CoreGraphics
import Foundation
import RoyalVNCKit

/// The production `RemoteDesktop`, backed by RoyalVNCKit (RFB with Apple
/// Remote Desktop, VNC and no-auth security types; Tight/ZRLE/Hextile…).
/// RoyalVNCKit calls its delegate on background queues; the delegate
/// extension hops every callback onto the main actor before touching state.
final class RoyalVNCDesktop: RemoteDesktop {
    var onEvent: ((RemoteDesktopEvent) -> Void)?

    private let connection: VNCConnection
    private var framebuffer: VNCFramebuffer?
    private var pendingCredential: (request: CredentialRequest, completion: (VNCCredential?) -> Void)?

    init(host: SavedHost, options: DesktopOptions) {
        connection = VNCConnection(settings: RoyalBridge.settings(host: host, options: options))
        connection.delegate = self
    }

    func connect() {
        connection.connect()
    }

    func disconnect() {
        connection.disconnect()
    }

    func supply(_ credential: RemoteCredential?) {
        guard let pending = pendingCredential else { return }
        pendingCredential = nil
        pending.completion(credential.map { RoyalBridge.credential($0, for: pending.request) })
    }

    func send(_ input: RemoteInput) {
        RoyalInput.apply(input, to: connection)
    }

    func snapshot() -> CGImage? {
        framebuffer?.cgImage
    }

    // MARK: Main-actor entry points for the delegate extension

    func receive(_ event: RemoteDesktopEvent) {
        onEvent?(event)
    }

    func receiveCredentialRequest(_ request: CredentialRequest, completion: @escaping (VNCCredential?) -> Void) {
        pendingCredential = (request, completion)
        onEvent?(.credentialNeeded(request))
    }

    func receiveFramebuffer(_ framebuffer: VNCFramebuffer) {
        self.framebuffer = framebuffer
        onEvent?(.framebufferChanged(framebuffer.cgSize))
    }
}
