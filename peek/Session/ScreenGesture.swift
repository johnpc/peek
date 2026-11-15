import CoreGraphics

/// What the touch layer recognized, in view coordinates. The UIKit view emits
/// these; `GestureLogic` turns them into remote input.
enum ScreenGesture: Equatable {
    case tap(CGPoint)
    case doubleTap(CGPoint)
    case secondaryTap(CGPoint)
    case dragBegan(CGPoint)
    case dragMoved(CGPoint)
    case dragEnded(CGPoint)
    case scroll(steps: CGSize, at: CGPoint)
    /// A trackpad/mouse pointer moved over the screen without clicking.
    case hover(CGPoint)
    /// Three-finger flick, mapped to the macOS trackpad gesture it mimics.
    case swipe(SwipeDirection)
}

enum SwipeDirection: Equatable, CaseIterable {
    case left, right, up, down

    /// macOS: swiping left goes to the Space on the right (⌃→), up is Mission
    /// Control (⌃↑), down is App Exposé (⌃↓).
    var keysym: UInt32 {
        switch self {
        case .left: return KeySym.right
        case .right: return KeySym.left
        case .up: return KeySym.up
        case .down: return KeySym.down
        }
    }

    var name: String {
        switch self {
        case .left: return "left"
        case .right: return "right"
        case .up: return "up"
        case .down: return "down"
        }
    }
}

/// Pure translation from gestures to the mouse events a VNC server expects.
enum GestureLogic {
    static func inputs(for gesture: ScreenGesture, transform: ScreenTransform, screen: CGSize) -> [RemoteInput] {
        func pixel(_ point: CGPoint) -> (x: Int, y: Int) {
            ScreenGeometry.framebufferPoint(point, transform: transform, screen: screen)
        }
        switch gesture {
        case .tap(let point):
            return click(.left, at: pixel(point))
        case .doubleTap(let point):
            let at = pixel(point)
            return click(.left, at: at) + click(.left, at: at)
        case .secondaryTap(let point):
            return click(.right, at: pixel(point))
        case .dragBegan(let point):
            let at = pixel(point)
            return [.move(x: at.x, y: at.y), .buttonDown(.left, x: at.x, y: at.y)]
        case .dragMoved(let point):
            let at = pixel(point)
            return [.move(x: at.x, y: at.y)]
        case .dragEnded(let point):
            let at = pixel(point)
            return [.buttonUp(.left, x: at.x, y: at.y)]
        case .scroll(let steps, let point):
            guard steps != .zero else { return [] }
            let at = pixel(point)
            return [.scroll(dx: Int(steps.width), dy: Int(steps.height), x: at.x, y: at.y)]
        case .hover(let point):
            let at = pixel(point)
            return [.move(x: at.x, y: at.y)]
        case .swipe(let direction):
            return [.keyDown(KeySym.controlLeft), .keyDown(direction.keysym),
                    .keyUp(direction.keysym), .keyUp(KeySym.controlLeft)]
        }
    }

    static func click(_ button: MouseButton, at: (x: Int, y: Int)) -> [RemoteInput] {
        [.move(x: at.x, y: at.y), .buttonDown(button, x: at.x, y: at.y), .buttonUp(button, x: at.x, y: at.y)]
    }
}
