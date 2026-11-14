import Foundation

enum MouseButton: Equatable {
    case left, middle, right
}

/// Modifier keys the keyboard bar can hold down ("sticky").
enum Modifier: CaseIterable, Hashable {
    case command, option, control, shift

    var symbol: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }

    var keysym: UInt32 {
        switch self {
        case .command: return KeySym.metaLeft
        case .option: return KeySym.altLeft
        case .control: return KeySym.controlLeft
        case .shift: return KeySym.shiftLeft
        }
    }
}

/// Everything the session can send to the remote machine. Coordinates are in
/// framebuffer pixels.
enum RemoteInput: Equatable {
    case move(x: Int, y: Int)
    case buttonDown(MouseButton, x: Int, y: Int)
    case buttonUp(MouseButton, x: Int, y: Int)
    /// Wheel steps: positive `dy` scrolls down, positive `dx` scrolls right.
    case scroll(dx: Int, dy: Int, x: Int, y: Int)
    case keyDown(UInt32)
    case keyUp(UInt32)
    case text(String)
}
