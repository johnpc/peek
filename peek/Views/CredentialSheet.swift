import SwiftUI

/// Asks for the remote machine's sign-in. Username is shown only when the
/// server's authentication wants one (Apple Remote Desktop does; plain VNC doesn't).
struct CredentialSheet: View {
    @ObservedObject var session: VNCSession
    @State private var username: String
    @State private var password = ""
    @State private var remember = false

    init(session: VNCSession) {
        self.session = session
        _username = State(initialValue: session.host.username)
    }

    private var needsUsername: Bool { session.credentialRequest?.needsUsername ?? false }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if needsUsername {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("Username")
                    }
                    SecureField("Password", text: $password)
                        .accessibilityIdentifier("Password")
                        .onSubmit(submit)
                    Toggle("Remember password", isOn: $remember)
                } footer: {
                    Text(needsUsername
                         ? "Use the account name and password you log in to \(session.host.displayName) with."
                         : "The VNC password set on \(session.host.displayName).")
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { session.cancelCredential() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect", action: submit)
                        .disabled(password.isEmpty)
                }
            }
        }
    }

    private func submit() {
        guard !password.isEmpty else { return }
        session.submitCredential(username: username, password: password, remember: remember)
    }
}
