import Combine
import Foundation

/// A short, in-memory diary of what connections did (resolved address, state
/// changes, errors), shown in Settings and shareable — so "it didn't connect"
/// comes with facts. Never written to disk; never leaves the device unless shared.
final class ConnectionLog: ObservableObject {
    static let capacity = 200

    @Published private(set) var lines: [String] = []
    var now: () -> Date = { Date() }

    private static let timeFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    func record(_ message: String) {
        lines.append("\(Self.timeFormat.string(from: now())) \(message)")
        if lines.count > Self.capacity { lines.removeFirst(lines.count - Self.capacity) }
    }

    func clear() {
        lines = []
    }

    var text: String { lines.joined(separator: "\n") }
}
