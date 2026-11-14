import SwiftUI

/// Draws the latest frame, fitted and zoomable, and forwards touch gestures
/// (translated to framebuffer pixels) to the session.
struct RemoteScreenView: View {
    let frame: CGImage
    let screenSize: CGSize
    let lastAction: String?
    let onGesture: (ScreenGesture, ScreenTransform) -> Void

    @State private var zoomState = ZoomState()

    var body: some View {
        GeometryReader { geometry in
            let transform = ScreenGeometry.transform(screen: screenSize, view: geometry.size,
                                                     zoom: zoomState.zoom, pan: zoomState.pan)
            ZStack(alignment: .topLeading) {
                Color.clear
                Image(decorative: frame, scale: 1)
                    .resizable()
                    .interpolation(zoomState.isZoomed ? .none : .high)
                    .frame(width: screenSize.width * transform.scale,
                           height: screenSize.height * transform.scale)
                    .offset(x: transform.offset.x, y: transform.offset.y)
                RemoteGestureView(
                    onGesture: { onGesture($0, transform) },
                    onPinch: { scale, delta in zoomState.pinch(by: scale, centroidDelta: delta) }
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("remoteScreen")
        .accessibilityLabel("Remote screen")
        .accessibilityValue(lastAction ?? "")
    }
}
