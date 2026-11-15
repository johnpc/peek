import Combine
import Foundation

/// User preferences that shape every connection. Backed by `UserDefaults`
/// (injected, so tests use a scratch suite).
final class SettingsStore: ObservableObject {
    static let colorDepths = [8, 16, 24]

    @Published var colorDepth: Int { didSet { defaults.set(colorDepth, forKey: Keys.colorDepth) } }
    @Published var isShared: Bool { didSet { defaults.set(isShared, forKey: Keys.isShared) } }
    @Published var syncsClipboard: Bool { didSet { defaults.set(syncsClipboard, forKey: Keys.clipboard) } }
    @Published var hasSeenGestureTips: Bool { didSet { defaults.set(hasSeenGestureTips, forKey: Keys.tips) } }
    @Published var pointerMode: PointerMode { didSet { defaults.set(pointerMode.rawValue, forKey: Keys.pointerMode) } }

    private let defaults: UserDefaults

    private enum Keys {
        static let colorDepth = "peek.settings.colorDepth"
        static let isShared = "peek.settings.isShared"
        static let tips = "peek.settings.hasSeenGestureTips"
        static let clipboard = "peek.settings.syncsClipboard"
        static let pointerMode = "peek.settings.pointerMode"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: Keys.colorDepth)
        colorDepth = SettingsStore.colorDepths.contains(stored) ? stored : 24
        isShared = defaults.object(forKey: Keys.isShared) as? Bool ?? true
        hasSeenGestureTips = defaults.bool(forKey: Keys.tips)
        syncsClipboard = defaults.object(forKey: Keys.clipboard) as? Bool ?? true
        pointerMode = PointerMode(rawValue: defaults.string(forKey: Keys.pointerMode) ?? "") ?? .direct
    }

    var options: DesktopOptions {
        DesktopOptions(colorDepth: colorDepth, isShared: isShared, syncsClipboard: syncsClipboard)
    }

    static func label(forDepth depth: Int) -> String {
        "\(depth)-bit"
    }
}
