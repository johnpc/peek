import UIKit

/// Touchpad mode: the whole screen acts like a trackpad. A one-finger drag
/// moves the Mac's pointer relatively, taps click where the pointer is, and a
/// long press then drag holds the mouse button down while moving.
extension RemoteGestureUIView {
    func installTouchpad(tap: UITapGestureRecognizer, doubleTap: UITapGestureRecognizer,
                         longPress: UILongPressGestureRecognizer) {
        touchpadPan.addTarget(self, action: #selector(touchpadPanned))
        touchpadPan.minimumNumberOfTouches = 1
        touchpadPan.maximumNumberOfTouches = 1
        touchpadPan.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue)]
        // A pan must not steal a long-press drag, and taps still need to win.
        touchpadPan.require(toFail: longPress)
        addGestureRecognizer(touchpadPan)
    }

    @objc func touchpadPanned(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self)
        recognizer.setTranslation(.zero, in: self)
        guard translation != .zero else { return }
        onGesture?(.pointerMoved(by: CGSize(width: translation.x, height: translation.y)))
    }

    /// Long press in touchpad mode: mouse down at the pointer, move relatively, release.
    func touchpadDragged(_ recognizer: UIGestureRecognizer) {
        let point = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            Haptics.dragStart()
            lastTouchpadDragPoint = point
            onGesture?(.dragBeganAtPointer)
        case .changed:
            let delta = CGSize(width: point.x - lastTouchpadDragPoint.x, height: point.y - lastTouchpadDragPoint.y)
            lastTouchpadDragPoint = point
            if delta != .zero { onGesture?(.pointerMoved(by: delta)) }
        case .ended, .cancelled, .failed:
            onGesture?(.dragEndedAtPointer)
        default:
            break
        }
    }
}
