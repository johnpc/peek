import SwiftUI
import UIKit

/// UIKit gesture layer over the remote screen: one-finger tap = click, double
/// tap = double click, two-finger tap = right click, long-press-and-drag =
/// mouse drag, two-finger pan = scroll, pinch (and move) = zoom.
struct RemoteGestureView: UIViewRepresentable {
    let onGesture: (ScreenGesture) -> Void
    let onPinch: (CGFloat, CGSize) -> Void
    let onPan: (CGSize) -> Void
    let isZoomed: () -> Bool

    func makeUIView(context: Context) -> RemoteGestureUIView {
        let view = RemoteGestureUIView()
        apply(to: view)
        return view
    }

    func updateUIView(_ uiView: RemoteGestureUIView, context: Context) {
        apply(to: uiView)
    }

    private func apply(to view: RemoteGestureUIView) {
        view.onGesture = onGesture
        view.onPinch = onPinch
        view.onPan = onPan
        view.isZoomed = isZoomed
    }
}
