import CoreGraphics
import Combine
import Foundation

/// One live connection to a host. Owns the `RemoteDesktop`, publishes its state
/// and latest frame, and routes input (see `VNCSession+Input`). Views render it;
/// logic lives in the small helpers it composes.
final class VNCSession: ObservableObject, Identifiable {
    let host: SavedHost

    @Published var state: RemoteState = .idle
    @Published var frame: CGImage?
    @Published var screenSize: CGSize = .zero
    @Published var credentialRequest: CredentialRequest?
    @Published var lastAction: String?
    @Published private(set) var heldModifiers: Set<Modifier> = []
    /// The Mac's pointer image (nil until the server sends one).
    @Published var cursor: RemoteCursor?
    /// Where the Mac's pointer is, in framebuffer pixels.
    @Published var pointer = PointerTracker()
    /// Short-lived notice for the session screen ("Copied from Mac").
    @Published var toast: String?

    /// Fired when the user asks to remember a password that just worked.
    var onRememberPassword: ((String) -> Void)?
    /// Fired when a Nearby host resolved to a different address than saved.
    var onAddressChanged: ((String) -> Void)?

    let makeDesktop: (SavedHost) -> RemoteDesktop
    let resolver: HostResolver?
    let pasteboard: Pasteboard
    var lastSeenPasteboardChange = 0
    let throttle: FrameThrottle
    var desktop: RemoteDesktop?
    var modifiers = ModifierLogic() { didSet { heldModifiers = modifiers.held } }
    /// Known-good password for this host (from the keychain, or typed and
    /// accepted earlier in this session). Reused on every reconnect; dropped
    /// only when the server rejects it.
    var savedPassword: String?
    var pendingRemember: String?
    /// Last password typed into the sign-in sheet; promoted to `savedPassword`
    /// once the server accepts it.
    var submittedPassword: String?
    /// Set once per connection attempt so a rejected saved password prompts
    /// instead of looping.
    var triedSavedPassword = false

    init(host: SavedHost,
         savedPassword: String? = nil,
         throttle: FrameThrottle = FrameThrottle(),
         resolver: HostResolver? = nil,
         pasteboard: Pasteboard = SystemPasteboard(),
         makeDesktop: @escaping (SavedHost) -> RemoteDesktop) {
        self.host = host
        self.savedPassword = savedPassword
        self.throttle = throttle
        self.resolver = resolver
        self.pasteboard = pasteboard
        self.makeDesktop = makeDesktop
        throttle.onFlush = { [weak self] in self?.refreshFrame() }
    }
}
