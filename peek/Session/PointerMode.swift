import Foundation

/// How a finger drives the Mac's pointer.
enum PointerMode: String, CaseIterable {
    /// Tap where you want to click (the default; what the tips describe).
    case direct
    /// The screen is a trackpad: dragging moves the pointer, tapping clicks
    /// wherever it is. Precise on a phone without zooming.
    case touchpad

    var toggled: PointerMode { self == .direct ? .touchpad : .direct }

    var label: String {
        switch self {
        case .direct: return "Touch mode"
        case .touchpad: return "Touchpad mode"
        }
    }

    var symbol: String {
        switch self {
        case .direct: return "hand.tap"
        case .touchpad: return "cursorarrow.motionlines"
        }
    }

    /// Framebuffer pixels moved per point of finger travel in touchpad mode.
    static let touchpadSpeed: CGFloat = 1.5
}
