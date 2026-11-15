import SwiftUI

/// Settings → recent connection diary, with share and clear.
struct ConnectionLogSection: View {
    @ObservedObject var log: ConnectionLog

    var body: some View {
        Section {
            if log.lines.isEmpty {
                Text("Nothing yet — connect to a computer and events show up here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(log.lines.suffix(8).reversed().enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(.caption.monospaced())
                        .lineLimit(2)
                }
                ShareLink(item: log.text) { Label("Share Full Log", systemImage: "square.and.arrow.up") }
                Button("Clear Log", role: .destructive) { log.clear() }
            }
        } header: {
            Text("Connection Log")
        } footer: {
            Text("Kept in memory only, for figuring out why a connection failed.")
        }
    }
}
