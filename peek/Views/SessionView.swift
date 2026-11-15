import Foundation
import SwiftUI
import UIKit

/// Full-screen remote desktop: the screen, a thin toolbar, the optional
/// keyboard bar, and the sign-in / status / first-run tip overlays.
struct SessionView: View {
    @ObservedObject var session: VNCSession
    @ObservedObject var settings: SettingsStore
    let onClose: () -> Void
    @State private var showKeyboard = false
    @State private var isToolbarCollapsed = false
    @State private var autoCollapseArmed = true
    @State private var isZoomed = false
    @State private var fitRequest = 0
    @State private var lifecycle = SessionLifecycle()
    @Environment(\.scenePhase) private var scenePhase

    private var isShowingScreen: Bool { session.state == .connected && session.frame != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let frame = session.frame {
                RemoteScreenView(frame: frame, screenSize: session.screenSize, lastAction: session.lastAction,
                                 isZoomed: $isZoomed, fitRequest: fitRequest) { gesture, transform in
                    settings.hasSeenGestureTips = true
                    session.perform(gesture, transform: transform)
                }
                .ignoresSafeArea(.container)
            }
            if !session.state.isActive || session.frame == nil {
                SessionStatusView(session: session, onClose: onClose)
            } else if session.state == .connecting {
                ReconnectingPill()
            }
            if let toast = session.toast {
                ToastView(text: toast) { session.toast = nil }
            }
            VStack(spacing: 0) {
                SessionToolbar(session: session, showKeyboard: $showKeyboard, isCollapsed: $isToolbarCollapsed,
                               isZoomed: isZoomed, onFit: { fitRequest += 1 }, onClose: onClose)
                Spacer()
                if isShowingScreen, !settings.hasSeenGestureTips, !showKeyboard {
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
                             onReturn: { session.press(.return) },
                             onHardwareKey: { action in
                                 switch action {
                                 case .key(let key): session.press(key)
                                 case .chord(let held, let text): session.chord(held, text: text)
                                 }
                             })
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
        .sheet(isPresented: credentialPresented) {
            CredentialSheet(session: session)
                .interactiveDismissDisabled()
        }
        .onAppear { session.connect() }
        .onChange(of: scenePhase) { _, phase in lifecycle.update(phase, session: session) }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            session.pasteboardDidChange()
        }
        .task(id: isShowingScreen && settings.hasSeenGestureTips) { await autoCollapseToolbar() }
        .onChange(of: isToolbarCollapsed) { _, _ in autoCollapseArmed = false }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }

    private var credentialPresented: Binding<Bool> {
        Binding(get: { session.credentialRequest != nil },
                set: { if !$0 { session.cancelCredential() } })
    }

    /// Once the screen is up and the tips are gone, tuck the toolbar away after
    /// a moment; the chevron brings it back. One-shot: as soon as the user
    /// collapses or expands it themselves, the timer stands down.
    private func autoCollapseToolbar() async {
        guard isShowingScreen, settings.hasSeenGestureTips, !isToolbarCollapsed else { return }
        try? await Task.sleep(for: .seconds(SessionView.autoCollapseDelay))
        if !Task.isCancelled, autoCollapseArmed, !showKeyboard { isToolbarCollapsed = true }
    }

    static let autoCollapseDelay: TimeInterval = 6
}
