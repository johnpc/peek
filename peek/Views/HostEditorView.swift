import SwiftUI

/// Add / edit a computer. Pure form; validation lives in `HostDraft`.
struct HostEditorView: View {
    @State var draft: HostDraft
    let onSave: (HostDraft) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Computer") {
                    TextField("Name", text: $draft.name)
                        .accessibilityIdentifier("Name")
                    TextField("Hostname or IP address", text: $draft.hostname)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .accessibilityIdentifier("Hostname")
                    TextField("Port", text: $draft.portText)
                        .keyboardType(.numberPad)
                        .accessibilityIdentifier("Port")
                }
                Section {
                    TextField("Username", text: $draft.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("Username")
                    SecureField("Password", text: $draft.password)
                        .accessibilityIdentifier("Password")
                    Toggle("Remember password", isOn: $draft.rememberPassword)
                } header: {
                    Text("Sign In")
                } footer: {
                    Text("For a Mac, use the account name and password you log in with. Leave blank to be asked when connecting.")
                }
            }
            .navigationTitle(draft.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(draft) }
                        .disabled(!draft.isValid)
                }
            }
        }
    }
}
