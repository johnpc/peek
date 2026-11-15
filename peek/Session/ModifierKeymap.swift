import Foundation

/// Which X11 keysyms stand for ⌘ and ⌥. macOS Screen Sharing (Apple Remote
/// Desktop) reads Hyper as ⌘ and Meta as ⌥ — verified against a real Mac,
/// where Meta typed through as a plain key. Everything else expects Super/Alt.
enum ModifierKeymap: Equatable {
    case standard
    case appleRemoteDesktop

    func keysym(for modifier: Modifier) -> UInt32 {
        switch (self, modifier) {
        case (.appleRemoteDesktop, .command): return KeySym.hyperLeft
        case (.appleRemoteDesktop, .option): return KeySym.metaLeft
        case (.standard, .command): return KeySym.superLeft
        case (.standard, .option): return KeySym.altLeft
        case (_, .control): return KeySym.controlLeft
        case (_, .shift): return KeySym.shiftLeft
        }
    }
}
