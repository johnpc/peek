import UIKit

/// Tiny taps so a remote click feels like a click. Generators are cheap and
/// silently no-op on devices without a Taptic Engine (and in the simulator).
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)

    static func click() {
        light.impactOccurred()
    }

    static func dragStart() {
        medium.impactOccurred()
    }
}
