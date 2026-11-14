import Foundation

/// Coalesces bursts of framebuffer updates into at most one redraw per
/// interval. A VNC server can send hundreds of small rectangles a second;
/// turning each into a `CGImage` would starve the UI.
final class FrameThrottle {
    typealias Scheduler = (TimeInterval, @escaping @MainActor () -> Void) -> Void

    var onFlush: (() -> Void)?

    private let interval: TimeInterval
    private let schedule: Scheduler
    private(set) var isPending = false

    init(interval: TimeInterval = 1.0 / 30.0, schedule: Scheduler? = nil) {
        self.interval = interval
        self.schedule = schedule ?? { delay, work in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                work()
            }
        }
    }

    func markDirty() {
        guard !isPending else { return }
        isPending = true
        schedule(interval) { [weak self] in
            guard let self else { return }
            self.isPending = false
            self.onFlush?()
        }
    }
}
