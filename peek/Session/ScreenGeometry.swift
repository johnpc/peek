import CoreGraphics

/// Where the remote image sits inside the view: a uniform scale and the view
/// coordinate of the image's top-left corner.
struct ScreenTransform: Equatable {
    var scale: CGFloat
    var offset: CGPoint
}

/// Pure math between view points and framebuffer pixels.
enum ScreenGeometry {
    /// Largest scale that fits the whole screen inside the view.
    static func fitScale(screen: CGSize, in view: CGSize) -> CGFloat {
        guard screen.width > 0, screen.height > 0 else { return 1 }
        return min(view.width / screen.width, view.height / screen.height)
    }

    /// Fit-and-center, then zoom about the view center, then pan — with the
    /// pan clamped so the image never leaves a gap it could have covered.
    static func transform(screen: CGSize, view: CGSize, zoom: CGFloat, pan: CGSize) -> ScreenTransform {
        let scale = fitScale(screen: screen, in: view) * zoom
        let scaled = CGSize(width: screen.width * scale, height: screen.height * scale)
        let centered = CGPoint(x: (view.width - scaled.width) / 2, y: (view.height - scaled.height) / 2)
        let offset = CGPoint(
            x: clampOffset(centered.x + pan.width, imageLength: scaled.width, viewLength: view.width),
            y: clampOffset(centered.y + pan.height, imageLength: scaled.height, viewLength: view.height)
        )
        return ScreenTransform(scale: scale, offset: offset)
    }

    /// Framebuffer pixel under a view point, clamped to the screen bounds.
    static func framebufferPoint(_ point: CGPoint, transform: ScreenTransform, screen: CGSize) -> (x: Int, y: Int) {
        guard transform.scale > 0 else { return (0, 0) }
        let x = (point.x - transform.offset.x) / transform.scale
        let y = (point.y - transform.offset.y) / transform.scale
        return (clamp(x, max: screen.width), clamp(y, max: screen.height))
    }

    private static func clampOffset(_ offset: CGFloat, imageLength: CGFloat, viewLength: CGFloat) -> CGFloat {
        if imageLength <= viewLength {
            return (viewLength - imageLength) / 2
        }
        return min(0, max(viewLength - imageLength, offset))
    }

    private static func clamp(_ value: CGFloat, max: CGFloat) -> Int {
        let upper = Swift.max(0, Int(max) - 1)
        return Swift.min(upper, Swift.max(0, Int(value.rounded(.down))))
    }
}
