import SwiftUI

/// Thin top bar over the remote screen: host + status, keyboard toggle,
/// disconnect. Collapses to a single chevron so the screen can go full-bleed.
struct SessionToolbar: View {
    @ObservedObject var session: VNCSession
    @Binding var showKeyboard: Bool
    @Binding var isCollapsed: Bool
    let isZoomed: Bool
    let onFit: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            if isCollapsed {
                Spacer()
                Button("Show controls", systemImage: "chevron.down.circle.fill") { isCollapsed = false }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(session.host.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(session.state.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .accessibilityIdentifier("status")
                }
                Spacer()
                if isZoomed {
                    Button("Fit to screen", systemImage: "arrow.down.right.and.arrow.up.left", action: onFit)
                }
                Button("Keyboard", systemImage: showKeyboard ? "keyboard.chevron.compact.down" : "keyboard") {
                    showKeyboard.toggle()
                }
                .disabled(session.state != .connected)
                Button("Hide controls", systemImage: "chevron.up.circle") { isCollapsed = true }
                Button("Disconnect", systemImage: "xmark.circle.fill", action: onClose)
            }
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isCollapsed ? AnyShapeStyle(.clear) : AnyShapeStyle(.ultraThinMaterial))
        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
    }
}
