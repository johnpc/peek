import SwiftUI

/// Thin top bar over the remote screen: host + status, keyboard toggle, disconnect.
struct SessionToolbar: View {
    @ObservedObject var session: VNCSession
    @Binding var showKeyboard: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 16) {
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
            Button("Keyboard", systemImage: showKeyboard ? "keyboard.chevron.compact.down" : "keyboard") {
                showKeyboard.toggle()
            }
            .disabled(session.state != .connected)
            Button("Disconnect", systemImage: "xmark.circle.fill", action: onClose)
        }
        .labelStyle(.iconOnly)
        .font(.title3)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
}
