import Combine
import Foundation

/// User preferences that shape every connection. Backed by `UserDefaults`
/// (injected, so tests use a scratch suite).
final class SettingsStore: ObservableObject {
    static let colorDepths = [8, 16, 24]

    @Published var colorDepth: Int { didSet { defaults.set(colorDepth, forKey: Keys.colorDepth) } }
    @Published var isShared: Bool { didSet { defaults.set(isShared, forKey: Keys.isShared) } }
    @Published var isScalingEnabled: Bool { didSet { defaults.set(isScalingEnabled, forKey: Keys.scaling) } }
    @Published var hasSeenGestureTips: Bool { didSet { defaults.set(hasSeenGestureTips, forKey: Keys.tips) } }

    private let defaults: UserDefaults

    private enum Keys {
        static let colorDepth = "peek.settings.colorDepth"
        static let isShared = "peek.settings.isShared"
        static let scaling = "peek.settings.isScalingEnabled"
        static let tips = "peek.settings.hasSeenGestureTips"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.integer(forKey: Keys.colorDepth)
        colorDepth = SettingsStore.colorDepths.contains(stored) ? stored : 24
        isShared = defaults.object(forKey: Keys.isShared) as? Bool ?? true
        isScalingEnabled = defaults.object(forKey: Keys.scaling) as? Bool ?? true
        hasSeenGestureTips = defaults.bool(forKey: Keys.tips)
    }

    var options: DesktopOptions {
        DesktopOptions(colorDepth: colorDepth, isShared: isShared, isScalingEnabled: isScalingEnabled)
    }

    static func label(forDepth depth: Int) -> String {
        "\(depth)-bit"
    }
}
