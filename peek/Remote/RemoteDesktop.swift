import CoreGraphics

/// Asked when the server wants to authenticate. Apple Remote Desktop (what
/// macOS Screen Sharing speaks) needs a username; classic VNC auth does not.
struct CredentialRequest: Equatable {
    var needsUsername: Bool
}

struct RemoteCredential: Equatable {
    var username: String
    var password: String
}

/// Tunables the user controls in Settings, applied per connection.
struct DesktopOptions: Equatable {
    /// 8, 16 or 24 bits per pixel. Lower is faster over weak Wi-Fi.
    var colorDepth: Int = 24
    /// Share the desktop with whoever is already connected instead of kicking them.
    var isShared: Bool = true
    /// Let text copied on the Mac land on this device's clipboard.
    var syncsClipboard: Bool = true
}

enum RemoteDesktopEvent: Equatable {
    case state(RemoteState)
    case credentialNeeded(CredentialRequest)
    /// The framebuffer was created or resized to this pixel size.
    case framebufferChanged(CGSize)
    /// Some region changed; call `snapshot()` to read the new contents.
    case framebufferUpdated
}

/// The seam between the app and a VNC implementation. `RoyalVNCDesktop` is the
/// real one; `MockDesktop` drives unit and acceptance tests. Implementations
/// must deliver `onEvent` on the main actor.
protocol RemoteDesktop: AnyObject {
    var onEvent: ((RemoteDesktopEvent) -> Void)? { get set }
    func connect()
    func disconnect()
    /// Answer a `credentialNeeded` event; `nil` cancels authentication.
    func supply(_ credential: RemoteCredential?)
    func send(_ input: RemoteInput)
    /// Current framebuffer contents, or nil before the first update.
    func snapshot() -> CGImage?
}

/// How the app obtains a desktop for a host — swapped for a mock under UI tests.
typealias RemoteDesktopFactory = (SavedHost, DesktopOptions) -> RemoteDesktop
