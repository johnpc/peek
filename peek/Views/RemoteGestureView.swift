import SwiftUI
import UIKit

/// UIKit gesture layer over the remote screen: one-finger tap = click, double
/// tap = double click, two-finger tap = right click, long-press-and-drag =
/// mouse drag, two-finger pan = scroll, pinch (and move) = zoom.
struct RemoteGestureView: UIViewRepresentable {
    let onGesture: (ScreenGesture) -> Void
    let onPinch: (CGFloat, CGSize) -> Void

    func makeUIView(context: Context) -> RemoteGestureUIView {
        let view = RemoteGestureUIView()
        view.onGesture = onGesture
        view.onPinch = onPinch
        return view
    }

    func updateUIView(_ uiView: RemoteGestureUIView, context: Context) {
        uiView.onGesture = onGesture
        uiView.onPinch = onPinch
    }
}

final class RemoteGestureUIView: UIView {
    var onGesture: ((ScreenGesture) -> Void)?
    var onPinch: ((CGFloat, CGSize) -> Void)?
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
        let pan = UIPanGestureRecognizer(target: self, action: #selector(scrolled))
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        [tap, doubleTap, twoFingerTap, longPress, pan, pinch].forEach(addGestureRecognizer)
    }

    required init?(coder: NSCoder) { nil }

    @objc func tapped(_ recognizer: UIGestureRecognizer) {
        onGesture?(.tap(recognizer.location(in: self)))
    }

    @objc func doubleTapped(_ recognizer: UIGestureRecognizer) {
        onGesture?(.doubleTap(recognizer.location(in: self)))
    }

    @objc func secondaryTapped(_ recognizer: UIGestureRecognizer) {
        onGesture?(.secondaryTap(recognizer.location(in: self)))
    }

    @objc func dragged(_ recognizer: UIGestureRecognizer) {
        let point = recognizer.location(in: self)
        switch recognizer.state {
        case .began: onGesture?(.dragBegan(point))
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

    @objc func pinched(_ recognizer: UIPinchGestureRecognizer) {
        let centroid = recognizer.location(in: self)
        if recognizer.state == .began { lastPinchCentroid = centroid }
        let delta = CGSize(width: centroid.x - lastPinchCentroid.x, height: centroid.y - lastPinchCentroid.y)
        lastPinchCentroid = centroid
        onPinch?(recognizer.scale, delta)
        recognizer.scale = 1
    }
}
