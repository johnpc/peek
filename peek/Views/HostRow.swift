import SwiftUI

struct HostRow: View {
    let host: SavedHost

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "desktopcomputer")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(host.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(host.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if host.rememberPassword {
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Password remembered")
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyHostsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Computers Yet", systemImage: "display")
        } description: {
            Text("Add a Mac or any VNC server by address, or pick one from Nearby — Macs with Screen Sharing turned on show up there automatically.")
        }
    }
}
