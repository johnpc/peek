import Foundation

/// Sticky-modifier bookkeeping for the keyboard bar: a tapped modifier stays
/// held until the next real key is sent, then every held modifier is released
/// — the way ⌘ works on a touch keyboard where you can't hold two keys.
struct ModifierLogic: Equatable {
    private(set) var held: Set<Modifier> = []

    /// The key events for toggling one modifier.
    mutating func toggle(_ modifier: Modifier) -> [RemoteInput] {
        if held.contains(modifier) {
            held.remove(modifier)
            return [.keyUp(modifier.keysym)]
        }
        held.insert(modifier)
        return [.keyDown(modifier.keysym)]
    }

    /// `press`, followed by the release of every held modifier.
    mutating func wrap(_ press: [RemoteInput]) -> [RemoteInput] {
        let releases = Modifier.allCases
            .filter { held.contains($0) }
            .map { RemoteInput.keyUp($0.keysym) }
        held = []
        return press + releases
    }

    /// Down + up for one keysym.
    static func press(_ keysym: UInt32) -> [RemoteInput] {
        [.keyDown(keysym), .keyUp(keysym)]
    }
}
