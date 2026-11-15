import Foundation
import SwiftUI
import UIKit

/// Keeps a session alive across brief trips to the background (iOS grants
/// ~30 s via a background task, enough for an app switch) and reconnects when
/// the stay was long enough for the socket to have died. Kept out of the view
/// so the decisions are unit-testable with injected clock and task hooks.
final class SessionLifecycle {
    typealias BeginHold = (@escaping () -> Void) -> UIBackgroundTaskIdentifier
    typealias EndHold = (UIBackgroundTaskIdentifier) -> Void

    private(set) var backgroundedAt: Date?
    private(set) var hold: UIBackgroundTaskIdentifier = .invalid
    var now: () -> Date = { Date() }
    private let beginHold: BeginHold
    private let endHold: EndHold

    init(beginHold: BeginHold? = nil, endHold: EndHold? = nil) {
        self.beginHold = beginHold ?? { expiry in
            UIApplication.shared.beginBackgroundTask(withName: "peek.session", expirationHandler: expiry)
        }
        self.endHold = endHold ?? { UIApplication.shared.endBackgroundTask($0) }
    }

    func update(_ phase: ScenePhase, session: VNCSession) {
        switch phase {
        case .background:
            backgroundedAt = now()
            if hold == .invalid {
                hold = beginHold { [weak self] in self?.releaseHold() }
            }
        case .active:
            releaseHold()
            if ReconnectPolicy.shouldReconnect(after: session.state, userDisconnected: false)
                || ReconnectPolicy.shouldRefresh(state: session.state, backgroundedAt: backgroundedAt, now: now()) {
                session.retry()
            }
            backgroundedAt = nil
        default:
            break
        }
    }

    private func releaseHold() {
        guard hold != .invalid else { return }
        endHold(hold)
        hold = .invalid
    }
}
