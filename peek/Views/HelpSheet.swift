import SwiftUI

/// "Can't see your Mac?" — the handful of reasons Nearby is empty or a
/// connection fails, in plain language, plus how to reach a Mac from outside
/// the house (peek has no relay of its own; Tailscale or a VPN does the job).
struct HelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    static let tips: [(symbol: String, title: String, text: String)] = [
        ("wifi", "Same network", "Your phone and the Mac must be on the same Wi-Fi (not a guest network, and not a VPN that blocks local traffic)."),
        ("display", "Screen Sharing on", "On the Mac: System Settings → General → Sharing → turn on Screen Sharing. Sign in with the Mac's user name and password."),
        ("lock.shield", "Local Network allowed", "iOS asks once whether peek may use the local network. If you declined, turn it on in Settings → Privacy & Security → Local Network."),
        ("plus.circle", "Add it by address", "If Nearby stays empty, tap + and enter the Mac's name (like johns-mac-mini.local) or its IP address."),
        ("globe", "Away from home", "peek doesn't tunnel through the internet. Install Tailscale (free) on both devices and add the Mac by its Tailscale name, or use your router's VPN."),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Self.tips, id: \.title) { tip in
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: tip.symbol)
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title).font(.headline)
                            Text(tip.text).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Can't see your Mac?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}
