import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Color depth", selection: $settings.colorDepth) {
                        ForEach(SettingsStore.colorDepths, id: \.self) { depth in
                            Text(SettingsStore.label(forDepth: depth)).tag(depth)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Picture")
                } footer: {
                    Text("Fewer bits means a faster, blockier picture — handy on weak Wi-Fi.")
                }
                Section {
                    Toggle("Share the screen", isOn: $settings.isShared)
                    Toggle("Let the Mac scale the picture", isOn: $settings.isScalingEnabled)
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Sharing keeps anyone already connected on the Mac instead of disconnecting them.")
                }
                Section("Help") {
                    Button("Show the touch controls tip again") { settings.hasSeenGestureTips = false }
                        .disabled(!settings.hasSeenGestureTips)
                }
                Section("About") {
                    LabeledContent("Version", value: SettingsView.version)
                    Link("Remote desktop engine: RoyalVNCKit (MIT)",
                         destination: URL(string: "https://github.com/royalapplications/royalvnc") ?? URL(fileURLWithPath: "/"))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return "\(short) (\(build))"
    }
}
