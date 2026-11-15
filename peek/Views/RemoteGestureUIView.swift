import UIKit

/// The UIKit gesture layer behind `RemoteGestureView`. Recognizers only
/// translate touches into `ScreenGesture`s; all meaning lives in `GestureLogic`.
final class RemoteGestureUIView: UIView {
    var onGesture: ((ScreenGesture) -> Void)?
    var onPinch: ((CGFloat, CGSize) -> Void)?
    /// Two-finger drag while zoomed moves the view (like Photos) instead of scrolling.
    var onPan: ((CGSize) -> Void)?
    var isZoomed: () -> Bool = { false }
    private var scroll = ScrollAccumulator()
    private var lastPinchCentroid: CGPoint = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(secondaryTapped))
        twoFingerTap.numberOfTouchesRequired = 2
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dragged))
        longPress.minimumPressDuration = 0.35
        let pan = UIPanGestureRecognizer(target: self, action: #selector(twoFingerPanned))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        let threeFingerPan = UIPanGestureRecognizer(target: self, action: #selector(scrolled))
        threeFingerPan.minimumNumberOfTouches = 3
        threeFingerPan.maximumNumberOfTouches = 3
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        [tap, doubleTap, twoFingerTap, longPress, pan, threeFingerPan, pinch].forEach(addGestureRecognizer)
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

    /// Zoomed: pan the view. Fit to screen: scroll the remote machine.
    @objc func twoFingerPanned(_ recognizer: UIPanGestureRecognizer) {
        guard isZoomed() else { return scrolled(recognizer) }
        let translation = recognizer.translation(in: self)
        recognizer.setTranslation(.zero, in: self)
        onPan?(CGSize(width: translation.x, height: translation.y))
    }

    @objc func scrolled(_ recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began { scroll.reset() }
        let translation = recognizer.translation(in: self)
        let steps = scroll.add(CGSize(width: translation.x, height: translation.y))
        recognizer.setTranslation(.zero, in: self)
        onGesture?(.scroll(steps: CGSize(width: steps.dx, height: steps.dy), at: recognizer.location(in: self)))
    }

    @objc func pinched(_ recognizer: UIPinchGestureRecognizer) {
        let centroid = recognizer.location(in: self)
        if recognizer.state == .began { lastPinchCentroid = centroid }
        let delta = CGSize(width: centroid.x - lastPinchCentroid.x, height: centroid.y - lastPinchCentroid.y)
        lastPinchCentroid = centroid
        onPinch?(recognizer.scale, delta)
        recognizer.scale = 1
    }
}
