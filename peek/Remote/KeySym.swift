/// X11 keysyms, which is what the RFB protocol sends for key events. Kept in
/// the app (rather than reaching into the VNC library) so input logic is
/// unit-testable without a connection.
enum KeySym {
    static let space: UInt32 = 0x0020
    static let backspace: UInt32 = 0xff08
    static let tab: UInt32 = 0xff09
    static let `return`: UInt32 = 0xff0d
    static let escape: UInt32 = 0xff1b
    static let home: UInt32 = 0xff50
    static let left: UInt32 = 0xff51
    static let up: UInt32 = 0xff52
    static let right: UInt32 = 0xff53
    static let down: UInt32 = 0xff54
    static let pageUp: UInt32 = 0xff55
    static let pageDown: UInt32 = 0xff56
    static let end: UInt32 = 0xff57
    static let shiftLeft: UInt32 = 0xffe1
    static let controlLeft: UInt32 = 0xffe3
    /// macOS Screen Sharing reads Meta as ⌘ and Alt as ⌥.
    static let metaLeft: UInt32 = 0xffe7
    static let altLeft: UInt32 = 0xffe9
    static let delete: UInt32 = 0xffff
}
