import UIKit

/// Draws the remote frame (as its layer contents) and turns touches into
/// `ScreenGesture`s: tap = click, double tap = double click, two-finger tap =
/// right click, long-press-and-drag = mouse drag, two fingers (when fit to
/// screen) or three fingers = scroll. Zoom and pan belong to the enclosing
/// `RemoteScreenScrollView`.
final class RemoteGestureUIView: UIView {
    var onGesture: ((ScreenGesture) -> Void)?
    /// Whether a two-finger drag should scroll the remote (true) or be left to
    /// the scroll view for panning (false). Set by `RemoteScreenScrollView`.
    var canScrollWithTwoFingers: () -> Bool = { true }
    let twoFingerScroll = UIPanGestureRecognizer()
    private var scroll = ScrollAccumulator()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        layer.contentsGravity = .resize
        layer.magnificationFilter = .nearest
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(secondaryTapped))
        twoFingerTap.numberOfTouchesRequired = 2
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dragged))
        longPress.minimumPressDuration = 0.35
        twoFingerScroll.addTarget(self, action: #selector(scrolled))
        twoFingerScroll.minimumNumberOfTouches = 2
        twoFingerScroll.maximumNumberOfTouches = 2
        let threeFingerScroll = UIPanGestureRecognizer(target: self, action: #selector(scrolled))
        threeFingerScroll.minimumNumberOfTouches = 3
        threeFingerScroll.maximumNumberOfTouches = 3
        [tap, doubleTap, twoFingerTap, longPress, twoFingerScroll, threeFingerScroll].forEach(addGestureRecognizer)
    }

    required init?(coder: NSCoder) { nil }

    @objc func tapped(_ recognizer: UIGestureRecognizer) {
        Haptics.click()
        onGesture?(.tap(recognizer.location(in: self)))
    }

    @objc func doubleTapped(_ recognizer: UIGestureRecognizer) {
        onGesture?(.doubleTap(recognizer.location(in: self)))
    }

    @objc func secondaryTapped(_ recognizer: UIGestureRecognizer) {
        Haptics.click()
        onGesture?(.secondaryTap(recognizer.location(in: self)))
    }

    @objc func dragged(_ recognizer: UIGestureRecognizer) {
        let point = recognizer.location(in: self)
        switch recognizer.state {
        case .began:
            Haptics.dragStart()
            onGesture?(.dragBegan(point))
        case .changed: onGesture?(.dragMoved(point))
        case .ended, .cancelled, .failed: onGesture?(.dragEnded(point))
        default: break
        }
    }

    @objc func scrolled(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began { scroll.reset() }
        let translation = recognizer.translation(in: self)
        let steps = scroll.add(CGSize(width: translation.x, height: translation.y))
        recognizer.setTranslation(.zero, in: self)
        onGesture?(.scroll(steps: CGSize(width: steps.dx, height: steps.dy), at: recognizer.location(in: self)))
    }
}

extension RemoteGestureUIView {
    /// UIView asks this for recognizers without a delegate of their own.
    override func gestureRecognizerShouldBegin(_ recognizer: UIGestureRecognizer) -> Bool {
        recognizer !== twoFingerScroll || canScrollWithTwoFingers()
    }
}
