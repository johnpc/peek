import Foundation

/// Clipboard in both directions.
///
/// Mac → device happens inside RoyalVNCKit: a server cut-text message lands on
/// the iOS pasteboard. The session only notices the change and surfaces a toast.
/// Device → Mac is deliberate: the Paste key types the pasteboard's text, so
/// iOS's "pasted from…" notice appears only when the user asked for it.
extension VNCSession {
    /// Pasting more than this would take minutes as key events; refuse politely.
    static let pasteLimit = 5_000

    func pasteFromDevice() {
        guard let text = pasteboard.string, !text.isEmpty else {
            toast = "Nothing to paste"
            return
        }
        guard text.count <= Self.pasteLimit else {
            toast = "That's too much text to paste (\(text.count) characters)"
            return
        }
        type(text)
        lastAction = "paste \(text.count) characters"
    }

    /// Call when the device pasteboard changes while connected: the only
    /// in-app source of a change is the Mac, so credit it.
    func pasteboardDidChange() {
        guard state == .connected, pasteboard.changeCount != lastSeenPasteboardChange else { return }
        lastSeenPasteboardChange = pasteboard.changeCount
        toast = "Copied from \(host.displayName)"
    }

    /// Remember the pasteboard state at connect time so the first change
    /// after connecting is the one that counts.
    func notePasteboardBaseline() {
        lastSeenPasteboardChange = pasteboard.changeCount
    }
}
