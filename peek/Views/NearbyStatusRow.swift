import Foundation
import SwiftUI
import UIKit

/// Shown under the saved list while nothing nearby has been found yet — or
/// when it never can be, because Local Network access was declined.
struct NearbyStatusRow: View {
    let status: DiscoveryStatus

    var body: some View {
        Section {
            switch status {
            case .searching:
                HStack(spacing: 12) {
                    ProgressView()
                    Text("Looking for Macs with Screen Sharing on…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("nearbySearching")
            case .localNetworkDenied:
                VStack(alignment: .leading, spacing: 8) {
                    Label("Local Network access is off", systemImage: "wifi.slash")
                        .font(.subheadline.weight(.semibold))
                    Text("peek can't find or reach computers on your network until it's allowed in Settings → Privacy & Security → Local Network.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                    }
                    .font(.footnote.weight(.semibold))
                }
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Nearby")
        }
    }
}
