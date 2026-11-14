import SwiftUI

/// Centered overlay while connecting, waiting for the first frame, or after
/// a drop/failure (with Try Again).
struct SessionStatusView: View {
    @ObservedObject var session: VNCSession
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let failure = session.state.failure {
                Image(systemName: failure.isAuthentication ? "lock.slash" : "wifi.exclamationmark")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text(failure.message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                Button("Try Again") { session.retry() }
                    .buttonStyle(.borderedProminent)
                Button("Close", action: onClose)
            } else if case .disconnected = session.state {
                Text("Disconnected")
                Button("Reconnect") { session.retry() }
                    .buttonStyle(.borderedProminent)
                Button("Close", action: onClose)
            } else {
                ProgressView()
                    .controlSize(.large)
                Text(session.frame == nil && session.state == .connected ? "Waiting for the screen…" : session.state.label)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}
