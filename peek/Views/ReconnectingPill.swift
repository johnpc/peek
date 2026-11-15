import SwiftUI

/// Small centered badge shown over the last frame while a dropped session
/// comes back, so the screen never blanks out for a hiccup.
struct ReconnectingPill: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text("Reconnecting…")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .accessibilityIdentifier("reconnecting")
    }
}
