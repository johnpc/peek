import SwiftUI

/// Sign-in sheet presentation and the one-shot toolbar auto-hide.
extension SessionView {
    var credentialPresented: Binding<Bool> {
        Binding(get: { session.credentialRequest != nil },
                set: { if !$0 { session.cancelCredential() } })
    }

    /// Once the screen is up and the tips are gone, tuck the toolbar away after
    /// a moment; the chevron brings it back. One-shot: as soon as the user
    /// collapses or expands it themselves, the timer stands down.
    func autoCollapseToolbar() async {
        guard isShowingScreen, settings.hasSeenGestureTips, !isToolbarCollapsed else { return }
        try? await Task.sleep(for: .seconds(SessionView.autoCollapseDelay))
        if !Task.isCancelled, autoCollapseArmed, !showKeyboard { isToolbarCollapsed = true }
    }

    static let autoCollapseDelay: TimeInterval = 6
}
