import SwiftUI
import UIKit

struct HostRow: View {
    let host: SavedHost
    var thumbnail: UIImage? = nil

    var body: some View {
        HStack(spacing: 14) {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel("Last screen of \(host.displayName)")
            } else {
                Image(systemName: "desktopcomputer")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 64)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(host.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(host.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
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
    var onHelp: () -> Void = {}

    var body: some View {
        ContentUnavailableView {
            Label("No Computers Yet", systemImage: "display")
        } description: {
            Text("Add a Mac or any VNC server by address, or pick one from Nearby — Macs with Screen Sharing turned on show up there automatically.")
        } actions: {
            Button("Can't see your Mac?", action: onHelp)
        }
    }
}
