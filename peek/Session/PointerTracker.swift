import CoreGraphics

/// Where the Mac believes its pointer is, derived from what we sent. Starts in
/// the middle of the screen; every mouse event we emit moves it.
struct PointerTracker: Equatable {
    private(set) var position: CGPoint = .zero

    mutating func reset(to screen: CGSize) {
        position = CGPoint(x: (screen.width / 2).rounded(.down), y: (screen.height / 2).rounded(.down))
    }

    mutating func observe(_ input: RemoteInput) {
        switch input {
        case .move(let x, let y), .buttonDown(_, let x, let y), .buttonUp(_, let x, let y), .scroll(_, _, let x, let y):
            position = CGPoint(x: x, y: y)
        case .keyDown, .keyUp, .text:
            break
        }
    }

    /// Touchpad mode: nudge by a finger delta (already in framebuffer pixels),
    /// clamped to the screen.
    mutating func move(by delta: CGSize, within screen: CGSize) {
        guard screen.width > 0, screen.height > 0 else { return }
        position = CGPoint(x: min(screen.width - 1, max(0, (position.x + delta.width).rounded())),
                           y: min(screen.height - 1, max(0, (position.y + delta.height).rounded())))
    }

    var pixel: (x: Int, y: Int) { (Int(position.x), Int(position.y)) }
}
