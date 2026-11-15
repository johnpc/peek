import UIKit

/// What a physical key press means to the session.
enum HardwareKeyAction: Equatable {
    case key(RemoteKey)
    /// A shortcut: modifiers held while typing `text` (e.g. ⌘ + "c").
    case chord(Set<Modifier>, String)
}

/// Pure mapping from hardware-keyboard presses (iPad keyboards, Bluetooth
/// keyboards) to remote actions. Plain typing is left to `UIKeyInput`; this
/// only claims the keys the software path can't express.
enum HardwareKeyMap {
    private static let specialKeys: [UIKeyboardHIDUsage: RemoteKey] = [
        .keyboardEscape: .escape, .keyboardTab: .tab, .keyboardReturnOrEnter: .return,
        .keyboardDeleteOrBackspace: .delete, .keyboardDeleteForward: .forwardDelete,
        .keyboardUpArrow: .upArrow, .keyboardDownArrow: .downArrow,
        .keyboardLeftArrow: .leftArrow, .keyboardRightArrow: .rightArrow,
    ]

    static func action(keyCode: UIKeyboardHIDUsage,
                       modifiers: UIKeyModifierFlags,
                       characters: String) -> HardwareKeyAction? {
        let held = self.modifiers(from: modifiers)
        if let key = specialKeys[keyCode] {
            return held.isEmpty ? .key(key) : .chord(held, characters.isEmpty ? key.label : characters)
        }
        let chordModifiers = held.subtracting([.shift])
        guard !chordModifiers.isEmpty, !characters.isEmpty else { return nil }
        return .chord(held, characters)
    }

    static func modifiers(from flags: UIKeyModifierFlags) -> Set<Modifier> {
        var set: Set<Modifier> = []
        if flags.contains(.command) { set.insert(.command) }
        if flags.contains(.alternate) { set.insert(.option) }
        if flags.contains(.control) { set.insert(.control) }
        if flags.contains(.shift) { set.insert(.shift) }
        return set
    }
}
