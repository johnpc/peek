import SwiftUI

/// Bonjour-discovered Screen Sharing servers that aren't saved yet.
struct NearbySection: View {
    let nearby: [DiscoveredHost]
    let onSelect: (DiscoveredHost) -> Void

    var body: some View {
        Section {
            ForEach(nearby) { host in
                Button { onSelect(host) } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "wifi")
                            .font(.title2)
                            .foregroundStyle(.tint)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(host.serviceName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(host.hostname)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityIdentifier("nearby-\(host.serviceName)")
            }
        } header: {
            Text("Nearby")
        } footer: {
            Text("Found on your network. Tap one to save it.")
        }
    }
}

/// Shown under the saved list while nothing nearby has been found yet.
struct NearbySearchingRow: View {
    var body: some View {
        Section {
            HStack(spacing: 12) {
                ProgressView()
                Text("Looking for Macs with Screen Sharing on…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("nearbySearching")
        } header: {
            Text("Nearby")
        }
    }
}
