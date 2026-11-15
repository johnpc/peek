import UIKit

/// Three-finger flicks become the macOS trackpad gestures people already know:
/// left/right switch Spaces, up is Mission Control, down is App Exposé.
/// A slow three-finger drag still scrolls; the scroll recognizer waits for
/// the swipes to fail first.
extension RemoteGestureUIView {
    func installSwipes(scroll: UIPanGestureRecognizer) {
        let directions: [(UISwipeGestureRecognizer.Direction, SwipeDirection)] = [
            (.left, .left), (.right, .right), (.up, .up), (.down, .down),
        ]
        for (uiDirection, _) in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(swiped))
            swipe.direction = uiDirection
            swipe.numberOfTouchesRequired = 3
            scroll.require(toFail: swipe)
            addGestureRecognizer(swipe)
        }
    }

    @objc func swiped(_ recognizer: UISwipeGestureRecognizer) {
        guard let direction = SwipeDirection(recognizer.direction) else { return }
        Haptics.dragStart()
        onGesture?(.swipe(direction))
    }
}

extension SwipeDirection {
    init?(_ direction: UISwipeGestureRecognizer.Direction) {
        switch direction {
        case .left: self = .left
        case .right: self = .right
        case .up: self = .up
        case .down: self = .down
        default: return nil
        }
    }
}
