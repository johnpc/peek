import Foundation
import SwiftUI
import UIKit

/// Full-screen remote desktop: the screen, a thin toolbar, the optional
/// keyboard bar, and the sign-in / status / first-run tip overlays.
struct SessionView: View {
    @ObservedObject var session: VNCSession
    @ObservedObject var settings: SettingsStore
    let onClose: () -> Void
    @State var showKeyboard = false
    @State var isToolbarCollapsed = false
    @State var autoCollapseArmed = true
    @State private var isZoomed = false
    @State private var fitRequest = 0
    @State private var lifecycle = SessionLifecycle()
    @Environment(\.scenePhase) private var scenePhase

    var isShowingScreen: Bool { session.state == .connected && session.frame != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let frame = session.frame {
                RemoteScreenView(frame: frame, screenSize: session.screenSize, lastAction: session.lastAction,
                                 cursor: session.cursor, pointer: session.pointer.position,
                                 pointerMode: settings.pointerMode,
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
                SessionToolbar(session: session, settings: settings, showKeyboard: $showKeyboard,
                               isCollapsed: $isToolbarCollapsed, isZoomed: isZoomed,
                               onFit: { fitRequest += 1 }, onClose: onClose)
                if isToolbarCollapsed {
                    EdgeRevealStrip { isToolbarCollapsed = false }
                }
                Spacer()
                if isShowingScreen, !settings.hasSeenGestureTips, !showKeyboard {
                    GestureTipsView { settings.hasSeenGestureTips = true }
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
                             },
                             accessory: AnyView(KeyboardBar(session: session)))
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
            }
        }
        // The key bar rides on the keyboard itself and the screen re-fits above
        // it (RemoteScreenScrollView), so the layout must not move for the keyboard.
        .ignoresSafeArea(.keyboard)
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
}
