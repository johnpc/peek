import SwiftUI

/// The home screen: saved computers, then anything advertising Screen Sharing nearby.
struct HostListView: View {
    @ObservedObject var hosts: HostStore
    @ObservedObject var discovery: DiscoveryStore
    @ObservedObject var thumbnails: ThumbnailStore
    @ObservedObject var model: HostListModel

    var body: some View {
        let nearby = model.nearby(discovery.nearby, saved: hosts.hosts)
        List {
            if hosts.hosts.isEmpty {
                EmptyHostsView()
            } else {
                Section("Saved") {
                    ForEach(hosts.hosts) { host in
                        Button { model.connect(host) } label: {
                            HostRow(host: host, thumbnail: thumbnails.image(for: host.id))
                        }
                            .accessibilityIdentifier("host-\(host.displayName)")
                            .swipeActions {
                                Button("Delete", role: .destructive) { model.delete(host) }
                                Button("Edit") { model.edit(host) }.tint(.orange)
                            }
                            .contextMenu { Button("Edit") { model.edit(host) } }
                    }
                }
            }
            if !nearby.isEmpty {
                NearbySection(nearby: nearby) { model.add($0) }
            } else if !hosts.hosts.isEmpty || discovery.status != .searching {
                NearbyStatusRow(status: discovery.status)
            }
        }
        .navigationTitle("peek")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Settings", systemImage: "gearshape") { model.showSettings = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add Computer", systemImage: "plus") { model.addHost() }
            }
        }
        .onAppear { discovery.start() }
        .onDisappear { discovery.stop() }
    }
}
