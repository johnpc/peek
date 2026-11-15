import SwiftUI

/// A thin, invisible strip along the top edge while the toolbar is tucked
/// away: swipe down from it (or tap it) to bring the controls back, so the
/// chevron isn't the only way out of full-bleed mode.
struct EdgeRevealStrip: View {
    let onReveal: () -> Void
    static let height: CGFloat = 24

    var body: some View {
        Color.clear
            .frame(height: Self.height)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        if value.translation.height > 10 { onReveal() }
                    }
            )
            .onTapGesture(perform: onReveal)
            .accessibilityElement()
            .accessibilityLabel("Reveal controls from the top edge")
            .accessibilityHint("Swipe down to reveal the toolbar")
            .accessibilityIdentifier("edgeReveal")
            .accessibilityAddTraits(.isButton)
    }
}
