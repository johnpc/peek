import SwiftUI

/// Bottom-center notice that fades out on its own ("Copied from Mac").
struct ToastView: View {
    let text: String
    let onDismiss: () -> Void
    static let duration: TimeInterval = 3.5

    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 90)
                .accessibilityIdentifier("toast")
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task(id: text) {
            try? await Task.sleep(for: .seconds(Self.duration))
            if !Task.isCancelled { onDismiss() }
        }
    }
}
