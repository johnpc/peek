import Foundation

/// Sign-in flow: answering the server's credential request, remembering a
/// password only once it has actually worked, and cancelling.
extension VNCSession {
    func submitCredential(username: String, password: String, remember: Bool) {
        credentialRequest = nil
        pendingRemember = remember ? password : nil
        submittedPassword = password
        desktop?.supply(RemoteCredential(username: username, password: password))
    }

    /// No-op once a credential has been submitted: SwiftUI re-fires the sheet's
    /// binding on programmatic dismissal, which must not cancel a sign-in.
    func cancelCredential() {
        guard credentialRequest != nil else { return }
        credentialRequest = nil
        desktop?.supply(nil)
    }
}
