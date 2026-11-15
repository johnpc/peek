import UIKit

/// iPad trackpad / mouse support and click feedback.
extension RemoteGestureUIView {
    /// Hover moves the Mac's cursor, a secondary click right-clicks, and
    /// scroll-wheel / two-finger-trackpad scrolling reaches the remote when
    /// the screen is fit (the scroll view pans it when zoomed).
    func installPointerSupport() {
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(hovered))
        let secondary = UITapGestureRecognizer(target: self, action: #selector(secondaryTapped))
        secondary.buttonMaskRequired = .secondary
        // The button mask is only consulted for pointer events; without this a
        // plain finger tap would also be treated as a right click.
        secondary.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        pointerScroll.addTarget(self, action: #selector(scrolled))
        pointerScroll.allowedScrollTypesMask = .all
        pointerScroll.allowedTouchTypes = [NSNumber(value: UITouch.TouchType.indirectPointer.rawValue)]
        pointerScroll.minimumNumberOfTouches = 0
        pointerScroll.maximumNumberOfTouches = 0
        [hover, secondary, pointerScroll].forEach(addGestureRecognizer)
    }

    @objc func hovered(_ recognizer: UIHoverGestureRecognizer) {
        guard recognizer.state == .changed || recognizer.state == .began else { return }
        onGesture?(.hover(recognizer.location(in: self)))
    }

    /// A brief ring where a click landed, so touch users see what they hit.
    func showRipple(at point: CGPoint) {
        let size: CGFloat = 36 / max(1, layer.affineTransform().a)
        let ring = CAShapeLayer()
        ring.path = UIBezierPath(ovalIn: CGRect(x: point.x - size / 2, y: point.y - size / 2,
                                                width: size, height: size)).cgPath
        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = UIColor.white.withAlphaComponent(0.9).cgColor
        ring.lineWidth = 2 / max(1, layer.affineTransform().a)
        layer.addSublayer(ring)
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        let grow = CABasicAnimation(keyPath: "transform.scale")
        grow.fromValue = 0.6
        grow.toValue = 1.4
        let group = CAAnimationGroup()
        group.animations = [fade, grow]
        group.duration = 0.35
        group.isRemovedOnCompletion = true
        ring.opacity = 0
        ring.add(group, forKey: "ripple")
        DispatchQueue.main.asyncAfter(deadline: .now() + group.duration) { ring.removeFromSuperlayer() }
    }
}
