import CoreGraphics

/// Pinch-to-zoom bookkeeping: zoom level plus a pan that follows the pinch
/// centroid, so "pinch and move" pans the magnified screen.
struct ZoomState: Equatable {
    static let minimum: CGFloat = 1
    static let maximum: CGFloat = 5

    private(set) var zoom: CGFloat = 1
    private(set) var pan: CGSize = .zero

    var isZoomed: Bool { zoom > Self.minimum }

    /// Apply an incremental pinch (scale relative to the last callback) and
    /// the movement of the pinch centroid since the last callback.
    mutating func pinch(by scale: CGFloat, centroidDelta: CGSize) {
        let next = min(Self.maximum, max(Self.minimum, zoom * scale))
        zoom = next
        if isZoomed {
            pan = CGSize(width: pan.width + centroidDelta.width, height: pan.height + centroidDelta.height)
        } else {
            pan = .zero
        }
    }

    /// Two-finger drag while zoomed: move the magnified view.
    mutating func pan(by delta: CGSize) {
        guard isZoomed else { return }
        pan = CGSize(width: pan.width + delta.width, height: pan.height + delta.height)
    }

    mutating func reset() {
        zoom = Self.minimum
        pan = .zero
    }
}
