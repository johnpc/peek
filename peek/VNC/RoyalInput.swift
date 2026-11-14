import Foundation
import RoyalVNCKit

/// Replays `RemoteInput` onto a live RoyalVNCKit connection.
nonisolated enum RoyalInput {
    static func apply(_ input: RemoteInput, to connection: VNCConnection) {
        switch input {
        case .move(let x, let y):
            connection.mouseMove(x: RoyalBridge.coordinate(x), y: RoyalBridge.coordinate(y))
        case .buttonDown(let button, let x, let y):
            connection.mouseButtonDown(RoyalBridge.button(button),
                                       x: RoyalBridge.coordinate(x), y: RoyalBridge.coordinate(y))
        case .buttonUp(let button, let x, let y):
            connection.mouseButtonUp(RoyalBridge.button(button),
                                     x: RoyalBridge.coordinate(x), y: RoyalBridge.coordinate(y))
        case .scroll(let dx, let dy, let x, let y):
            scroll(dx: dx, dy: dy, x: RoyalBridge.coordinate(x), y: RoyalBridge.coordinate(y), on: connection)
        case .keyDown(let keysym):
            connection.keyDown(VNCKeyCode(keysym))
        case .keyUp(let keysym):
            connection.keyUp(VNCKeyCode(keysym))
        case .text(let text):
            for key in VNCKeyCode.keyCodesFrom(characters: text) {
                connection.keyDown(key)
                connection.keyUp(key)
            }
        }
    }

    private static func scroll(dx: Int, dy: Int, x: UInt16, y: UInt16, on connection: VNCConnection) {
        if dy != 0 {
            connection.mouseWheel(dy > 0 ? .down : .up, x: x, y: y, steps: UInt32(abs(dy)))
        }
        if dx != 0 {
            connection.mouseWheel(dx > 0 ? .right : .left, x: x, y: y, steps: UInt32(abs(dx)))
        }
    }
}
