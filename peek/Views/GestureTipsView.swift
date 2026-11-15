import SwiftUI

/// One-time cheat sheet shown over the first connected screen: how touches map
/// to mouse actions. Dismissed with "Got it" and never shown again.
struct GestureTipsView: View {
    let onDismiss: () -> Void

    private static let tips: [(symbol: String, text: String)] = [
        ("hand.tap", "Tap to click, double-tap to double-click"),
        ("hand.point.up.left.and.text", "Two-finger tap for a right click"),
        ("hand.draw", "Press and hold, then drag to move things"),
        ("arrow.up.and.down", "Drag with two fingers to scroll"),
        ("arrow.up.left.and.down.right.magnifyingglass", "Pinch to zoom; two fingers then pan, three fingers scroll"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controls")
                .font(.headline)
            ForEach(Self.tips, id: \.text) { tip in
                Label(tip.text, systemImage: tip.symbol)
                    .font(.subheadline)
            }
            Button("Got it", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .accessibilityIdentifier("gestureTips")
    }
}
