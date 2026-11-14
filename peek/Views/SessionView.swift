import SwiftUI

/// Full-screen remote desktop: the screen, a thin toolbar, the optional
/// keyboard bar, and the sign-in / status / first-run tip overlays.
struct SessionView: View {
    @ObservedObject var session: VNCSession
    @ObservedObject var settings: SettingsStore
    let onClose: () -> Void
    @State private var showKeyboard = false
    @State private var isToolbarCollapsed = false
    @Environment(\.scenePhase) private var scenePhase

    private var isShowingScreen: Bool { session.state == .connected && session.frame != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let frame = session.frame {
                RemoteScreenView(frame: frame, screenSize: session.screenSize,
                                 lastAction: session.lastAction) { gesture, transform in
                    session.perform(gesture, transform: transform)
                }
                .ignoresSafeArea()
            }
            if !session.state.isActive || session.frame == nil {
                SessionStatusView(session: session, onClose: onClose)
            }
            VStack(spacing: 0) {
                SessionToolbar(session: session, showKeyboard: $showKeyboard,
                               isCollapsed: $isToolbarCollapsed, onClose: onClose)
                Spacer()
                if isShowingScreen, !settings.hasSeenGestureTips {
                    GestureTipsView { settings.hasSeenGestureTips = true }
                }
                if showKeyboard, session.state == .connected {
                    KeyboardBar(session: session)
                }
            }
            if showKeyboard {
                KeyInputView(isActive: showKeyboard,
                             onText: { session.type($0) },
                             onBackspace: { session.press(.delete) },
                             onReturn: { session.press(.return) })
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
        .sheet(isPresented: credentialPresented) {
            CredentialSheet(session: session)
                .interactiveDismissDisabled()
        }
        .onAppear { session.connect() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, ReconnectPolicy.shouldReconnect(after: session.state, userDisconnected: false) {
                session.retry()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var credentialPresented: Binding<Bool> {
        Binding(get: { session.credentialRequest != nil },
                set: { if !$0 { session.cancelCredential() } })
    }
}
