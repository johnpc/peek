import Foundation

/// A named key combination the keyboard bar can send in one tap.
struct KeyChord: Equatable, Identifiable {
    let label: String
    let modifiers: Set<Modifier>
    let keysym: UInt32

    var id: String { label }

    static let functionKeys: [KeyChord] = (1...12).map {
        KeyChord(label: "F\($0)", modifiers: [], keysym: KeySym.function($0))
    }

    /// Things people reach for on a Mac that are awkward to type remotely.
    /// (Media keys are left out: macOS's VNC server ignores them.)
    static let macActions: [KeyChord] = [
        KeyChord(label: "Spotlight", modifiers: [.command], keysym: KeySym.space),
        KeyChord(label: "Switch App", modifiers: [.command], keysym: KeySym.tab),
        KeyChord(label: "Close Window", modifiers: [.command], keysym: UInt32(Character("w").asciiValue ?? 0x77)),
        KeyChord(label: "Quit App", modifiers: [.command], keysym: UInt32(Character("q").asciiValue ?? 0x71)),
        KeyChord(label: "Force Quit…", modifiers: [.command, .option], keysym: KeySym.escape),
        KeyChord(label: "Screenshot to Clipboard", modifiers: [.command, .shift, .control],
                 keysym: UInt32(Character("4").asciiValue ?? 0x34)),
        KeyChord(label: "Lock Screen", modifiers: [.command, .control], keysym: UInt32(Character("q").asciiValue ?? 0x71)),
        KeyChord(label: "Log Out…", modifiers: [.command, .shift], keysym: UInt32(Character("q").asciiValue ?? 0x71)),
    ]
}
