import SwiftUI

/// Draws the latest frame inside a zoomable scroll view and forwards touch
/// gestures (already in framebuffer pixels) to the session.
struct RemoteScreenView: View {
    let frame: CGImage
    let screenSize: CGSize
    let lastAction: String?
    @Binding var isZoomed: Bool
    /// Bump to ask the view to zoom back out to fit.
    var fitRequest: Int = 0
    let onGesture: (ScreenGesture, ScreenTransform) -> Void

    var body: some View {
        RemoteScreenHost(frame: frame, screenSize: screenSize, isZoomed: $isZoomed,
                         fitRequest: fitRequest, onGesture: onGesture)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("remoteScreen")
            .accessibilityLabel("Remote screen \(Int(screenSize.width))×\(Int(screenSize.height))")
            .accessibilityValue(lastAction ?? "")
    }
}

/// UIKit bridge for `RemoteScreenScrollView`.
struct RemoteScreenHost: UIViewRepresentable {
    let frame: CGImage
    let screenSize: CGSize
    @Binding var isZoomed: Bool
    let fitRequest: Int
    let onGesture: (ScreenGesture, ScreenTransform) -> Void

    final class Coordinator {
        var fitRequest = 0
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> RemoteScreenScrollView {
        let view = RemoteScreenScrollView()
        view.backgroundColor = .black
        wire(view)
        return view
    }

    func updateUIView(_ view: RemoteScreenScrollView, context: Context) {
        wire(view)
        view.display(frame, size: screenSize)
        if context.coordinator.fitRequest != fitRequest {
            context.coordinator.fitRequest = fitRequest
            view.fit()
        }
    }

    private func wire(_ view: RemoteScreenScrollView) {
        // Content coordinates are framebuffer pixels: identity transform.
        view.content.onGesture = { onGesture($0, ScreenTransform(scale: 1, offset: .zero)) }
        view.onZoomChanged = { zoomed in
            if zoomed != isZoomed { DispatchQueue.main.async { isZoomed = zoomed } }
        }
    }
}
