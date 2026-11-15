import SwiftUI

/// Asks for the remote machine's sign-in. Username is shown only when the
/// server's authentication wants one (Apple Remote Desktop does; plain VNC doesn't).
struct CredentialSheet: View {
    @ObservedObject var session: VNCSession
    @State private var username: String
    @State private var password = ""
    @State private var remember = false
    @State private var revealPassword = false
    @FocusState private var focused: Field?

    private enum Field { case username, password }

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
                            .focused($focused, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focused = .password }
                            .accessibilityIdentifier("Username")
                    }
                    HStack {
                        PasswordField(text: $password, revealed: revealPassword)
                            .focused($focused, equals: .password)
                            .submitLabel(.go)
                            .onSubmit(submit)
                        Button(revealPassword ? "Hide password" : "Show password",
                               systemImage: revealPassword ? "eye.slash" : "eye") { revealPassword.toggle() }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                    }
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
            .onAppear { focused = needsUsername && username.isEmpty ? .username : .password }
        }
    }

    private func submit() {
        guard !password.isEmpty else { return }
        session.submitCredential(username: username, password: password, remember: remember)
    }
}

/// Secure by default, plain text when revealed; same identifier either way so
/// tests and AutoFill see one field.
struct PasswordField: View {
    @Binding var text: String
    let revealed: Bool

    var body: some View {
        Group {
            if revealed {
                TextField("Password", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                SecureField("Password", text: $text)
            }
        }
        // Deliberately no `.textContentType(.password)`: this is a remote
        // computer's login, and iOS's "Save Password?" sheet would pop over
        // the form (peek keeps the password in its own keychain entry instead).
        .accessibilityIdentifier("Password")
    }
}
