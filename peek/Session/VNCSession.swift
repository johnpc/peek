import CoreGraphics
import Combine
import Foundation

/// One live connection to a host. Owns the `RemoteDesktop`, publishes its state
/// and latest frame, and routes input (see `VNCSession+Input`). Views render it;
/// logic lives in the small helpers it composes.
final class VNCSession: ObservableObject, Identifiable {
    let host: SavedHost

    @Published private(set) var state: RemoteState = .idle
    @Published private(set) var frame: CGImage?
    @Published private(set) var screenSize: CGSize = .zero
    @Published private(set) var credentialRequest: CredentialRequest?
    @Published var lastAction: String?
    @Published private(set) var heldModifiers: Set<Modifier> = []

    /// Fired when the user asks to remember a password that just worked.
    var onRememberPassword: ((String) -> Void)?

    private let makeDesktop: () -> RemoteDesktop
    private let throttle: FrameThrottle
    private(set) var desktop: RemoteDesktop?
    var modifiers = ModifierLogic() { didSet { heldModifiers = modifiers.held } }
    private var savedPassword: String?
    private var pendingRemember: String?

    init(host: SavedHost,
         savedPassword: String? = nil,
         throttle: FrameThrottle = FrameThrottle(),
         makeDesktop: @escaping () -> RemoteDesktop) {
        self.host = host
        self.savedPassword = savedPassword
        self.throttle = throttle
        self.makeDesktop = makeDesktop
        throttle.onFlush = { [weak self] in self?.refreshFrame() }
    }

    func connect() {
        let desktop = makeDesktop()
        desktop.onEvent = { [weak self] event in self?.handle(event) }
        self.desktop = desktop
        frame = nil
        credentialRequest = nil
        state = .connecting
        desktop.connect()
    }

    /// Reconnect from a failure. After a rejected password the saved one is
    /// dropped so the user is asked again instead of looping.
    func retry() {
        if state.failure?.isAuthentication == true { savedPassword = nil }
        connect()
    }

    func disconnect() {
        desktop?.disconnect()
    }

    func submitCredential(username: String, password: String, remember: Bool) {
        credentialRequest = nil
        pendingRemember = remember ? password : nil
        desktop?.supply(RemoteCredential(username: username, password: password))
    }

    /// No-op once a credential has been submitted: SwiftUI re-fires the sheet's
    /// binding on programmatic dismissal, which must not cancel a sign-in.
    func cancelCredential() {
        guard credentialRequest != nil else { return }
        credentialRequest = nil
        desktop?.supply(nil)
    }

    private func handle(_ event: RemoteDesktopEvent) {
        switch event {
        case .state(let next):
            state = next
            if next == .connected, let password = pendingRemember {
                pendingRemember = nil
                onRememberPassword?(password)
            }
        case .credentialNeeded(let request):
            if let password = savedPassword {
                savedPassword = nil
                desktop?.supply(RemoteCredential(username: host.username, password: password))
            } else {
                credentialRequest = request
            }
        case .framebufferChanged(let size):
            screenSize = size
            throttle.markDirty()
        case .framebufferUpdated:
            throttle.markDirty()
        }
    }

    private func refreshFrame() {
        frame = desktop?.snapshot()
    }
}
