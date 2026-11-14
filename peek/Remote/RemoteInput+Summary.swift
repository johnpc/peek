import Foundation

extension MouseButton {
    var name: String {
        switch self {
        case .left: return "left"
        case .middle: return "middle"
        case .right: return "right"
        }
    }
}

extension RemoteInput {
    /// One-line, human-readable form, shown as the remote screen's
    /// accessibility value so acceptance tests (and a curious user) can see
    /// what was actually sent.
    var summary: String {
        switch self {
        case .move(let x, let y):
            return "move to \(x),\(y)"
        case .buttonDown(let button, let x, let y):
            return "\(button.name) down at \(x),\(y)"
        case .buttonUp(let button, let x, let y):
            return "\(button.name) up at \(x),\(y)"
        case .scroll(let dx, let dy, let x, let y):
            return "scroll \(dx),\(dy) at \(x),\(y)"
        case .keyDown(let key):
            return "key down \(key)"
        case .keyUp(let key):
            return "key up \(key)"
        case .text(let text):
            return "text \(text)"
        }
    }
}
