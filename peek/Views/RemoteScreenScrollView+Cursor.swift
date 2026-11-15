import UIKit

/// Draws the Mac's pointer on top of the frame at its tracked position. The
/// layer lives in content coordinates (framebuffer pixels) and is counter-
/// scaled so the arrow stays the same size on screen at any zoom.
extension RemoteScreenScrollView {
    func showCursor(_ cursor: RemoteCursor?, at position: CGPoint) {
        guard let cursor else {
            cursorLayer.isHidden = true
            return
        }
        if cursorLayer.superlayer == nil { content.layer.addSublayer(cursorLayer) }
        cursorLayer.isHidden = false
        cursorLayer.contents = cursor.image
        cursorLayer.bounds = CGRect(x: 0, y: 0, width: CGFloat(cursor.image.width), height: CGFloat(cursor.image.height))
        cursorLayer.anchorPoint = CGPoint(x: cursor.hotspot.x / max(1, cursorLayer.bounds.width),
                                          y: cursor.hotspot.y / max(1, cursorLayer.bounds.height))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        cursorLayer.position = position
        updateCursorScale()
        CATransaction.commit()
    }

    /// Keep the pointer a constant on-screen size while the content zooms.
    func updateCursorScale() {
        let inverse = 1 / max(zoomScale, 0.01)
        cursorLayer.transform = CATransform3DMakeScale(inverse, inverse, 1)
    }
}
