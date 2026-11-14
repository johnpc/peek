import Foundation

/// Non-character keys the keyboard bar offers (the ones a phone keyboard lacks).
enum RemoteKey: CaseIterable, Hashable {
    case escape, tab, `return`, delete, forwardDelete
    case upArrow, downArrow, leftArrow, rightArrow

    var label: String {
        switch self {
        case .escape: return "esc"
        case .tab: return "tab"
        case .return: return "return"
        case .delete: return "delete"
        case .forwardDelete: return "⌦"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        }
    }

    var keysym: UInt32 {
        switch self {
        case .escape: return KeySym.escape
        case .tab: return KeySym.tab
        case .return: return KeySym.return
        case .delete: return KeySym.backspace
        case .forwardDelete: return KeySym.delete
        case .upArrow: return KeySym.up
        case .downArrow: return KeySym.down
        case .leftArrow: return KeySym.left
        case .rightArrow: return KeySym.right
        }
    }
}
