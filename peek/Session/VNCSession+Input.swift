import CoreGraphics
import Foundation

/// Input routing. Each public action sends its events and records a one-line
/// `lastAction` (surfaced as the remote screen's accessibility value) so
/// behaviour is observable without a real server.
extension VNCSession {
    func perform(_ gesture: ScreenGesture, transform: ScreenTransform) {
        let inputs = GestureLogic.inputs(for: gesture, transform: transform, screen: screenSize, pointer: pointer)
        guard !inputs.isEmpty else { return }
        send(inputs, action: VNCSession.describe(gesture, inputs: inputs))
    }

    func press(_ key: RemoteKey) {
        let inputs = modifiers.wrap(ModifierLogic.press(key.keysym))
        send(inputs, action: "key \(key.label)")
    }

    func type(_ text: String) {
        guard !text.isEmpty else { return }
        let inputs = modifiers.wrap([.text(text)])
        send(inputs, action: "text \(text)")
    }

    /// A hardware-keyboard shortcut: hold `held`, send `text`, release — on top
    /// of any sticky modifiers already held from the keyboard bar.
    func chord(_ held: Set<Modifier>, text: String) {
        let keymap = modifiers.keymap
        let ordered = Modifier.allCases.filter { held.contains($0) }
        let downs = ordered.map { RemoteInput.keyDown(keymap.keysym(for: $0)) }
        let ups = ordered.reversed().map { RemoteInput.keyUp(keymap.keysym(for: $0)) }
        let inputs = modifiers.wrap(downs + [.text(text)] + ups)
        send(inputs, action: ordered.map(\.symbol).joined() + text)
    }

    func toggle(_ modifier: Modifier) {
        let inputs = modifiers.toggle(modifier)
        let verb = modifiers.held.contains(modifier) ? "hold" : "release"
        send(inputs, action: "\(verb) \(modifier.symbol)")
    }

    private func send(_ inputs: [RemoteInput], action: String) {
        for input in inputs {
            desktop?.send(input)
            pointer.observe(input)
        }
        lastAction = action
    }

    static func describe(_ gesture: ScreenGesture, inputs: [RemoteInput]) -> String {
        switch gesture {
        case .tap: return "click left" + location(inputs)
        case .doubleTap: return "double click" + location(inputs)
        case .secondaryTap: return "click right" + location(inputs)
        case .dragBegan: return "drag start" + location(inputs)
        case .dragMoved: return "drag" + location(inputs)
        case .dragEnded: return "drag end" + location(inputs)
        case .scroll(let steps, _): return "scroll \(Int(steps.width)),\(Int(steps.height))"
        case .hover: return "move" + location(inputs)
        case .swipe(let direction): return "swipe \(direction.name)"
        case .pointerMoved: return "move" + location(inputs)
        case .clickAtPointer(let button, let count): return (count > 1 ? "double click" : "click \(button.name)") + location(inputs)
        case .dragBeganAtPointer: return "drag start" + location(inputs)
        case .dragEndedAtPointer: return "drag end" + location(inputs)
        }
    }

    private static func location(_ inputs: [RemoteInput]) -> String {
        switch inputs.last {
        case .move(let x, let y), .buttonDown(_, let x, let y), .buttonUp(_, let x, let y):
            return " at \(x),\(y)"
        default:
            return ""
        }
    }
}
