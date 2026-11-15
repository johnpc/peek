import CoreGraphics

/// Touchpad-mode gestures act at the tracked pointer, not under the finger.
extension GestureLogic {
    static func touchpadInputs(for gesture: ScreenGesture, screen: CGSize, pointer: PointerTracker) -> [RemoteInput] {
        var tracker = pointer
        switch gesture {
        case .pointerMoved(let delta):
            let scaled = CGSize(width: delta.width * PointerMode.touchpadSpeed,
                                height: delta.height * PointerMode.touchpadSpeed)
            tracker.move(by: scaled, within: screen)
            return [.move(x: tracker.pixel.x, y: tracker.pixel.y)]
        case .clickAtPointer(let button, let count):
            return Array(repeating: click(button, at: tracker.pixel), count: max(1, count)).flatMap { $0 }
        case .dragBeganAtPointer:
            return [.buttonDown(.left, x: tracker.pixel.x, y: tracker.pixel.y)]
        case .dragEndedAtPointer:
            return [.buttonUp(.left, x: tracker.pixel.x, y: tracker.pixel.y)]
        default:
            return []
        }
    }
}
