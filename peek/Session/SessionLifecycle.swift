import Foundation
import SwiftUI

/// Tracks how long the app sat in the background and reconnects a session
/// when iOS has likely torn its socket down. Kept out of the view so the
/// decision is unit-testable with an injected clock.
final class SessionLifecycle {
    private(set) var backgroundedAt: Date?
    var now: () -> Date = { Date() }

    func update(_ phase: ScenePhase, session: VNCSession) {
        switch phase {
        case .background:
            backgroundedAt = now()
        case .active:
            if ReconnectPolicy.shouldReconnect(after: session.state, userDisconnected: false)
                || ReconnectPolicy.shouldRefresh(state: session.state, backgroundedAt: backgroundedAt, now: now()) {
                session.retry()
            }
            backgroundedAt = nil
        default:
            break
        }
    }
}
