import UIKit

/// The remote screen inside a real scroll view, so zooming and panning feel
/// like Photos: pinch zooms around the fingers with bounce, two fingers pan
/// when zoomed, and one finger is left free for clicks. The content view is
/// `RemoteGestureUIView`, sized in points to the framebuffer, so gesture
/// locations in it ARE framebuffer pixels.
final class RemoteScreenScrollView: UIScrollView, UIScrollViewDelegate {
    static let maximumMagnification: CGFloat = 5
    let content = RemoteGestureUIView()
    let cursorLayer = CALayer()
    var onZoomChanged: ((Bool) -> Void)?
    private(set) var screenSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        bouncesZoom = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        contentInsetAdjustmentBehavior = .never
        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.maximumNumberOfTouches = 2
        // When fit to screen there is nothing to pan, so two fingers scroll the
        // remote machine instead; the content view's recognizer takes over.
        panGestureRecognizer.require(toFail: content.twoFingerScroll)
        panGestureRecognizer.require(toFail: content.pointerScroll)
        content.canScrollWithTwoFingers = { [weak self] in self.map { !$0.isZoomed } ?? true }
        addSubview(content)
    }

    required init?(coder: NSCoder) { nil }

    var fitScale: CGFloat {
        guard screenSize.width > 0, screenSize.height > 0, bounds.width > 0, bounds.height > 0 else { return 1 }
        return min(bounds.width / screenSize.width, bounds.height / screenSize.height)
    }

    var isZoomed: Bool { zoomScale > minimumZoomScale * 1.01 }

    /// Show a new frame; re-fit when the remote screen changes size.
    func display(_ image: CGImage, size: CGSize) {
        if size != screenSize {
            screenSize = size
            content.frame = CGRect(origin: .zero, size: size)
            contentSize = size
            applyFit(resetZoom: true)
        }
        content.layer.contents = image
    }

    func fit() {
        setZoomScale(minimumZoomScale, animated: true)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let wasFit = !isZoomed
        applyFit(resetZoom: wasFit)
        center()
    }

    private func applyFit(resetZoom: Bool) {
        let fit = fitScale
        minimumZoomScale = fit
        maximumZoomScale = fit * Self.maximumMagnification
        if resetZoom || zoomScale < fit { zoomScale = fit }
        center()
    }

    /// Keep the image centered while it is smaller than the viewport.
    private func center() {
        let dx = max(0, (bounds.width - contentSize.width) / 2)
        let dy = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: dy, left: dx, bottom: dy, right: dx)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { content }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        center()
        updateCursorScale()
        onZoomChanged?(isZoomed)
    }
}
