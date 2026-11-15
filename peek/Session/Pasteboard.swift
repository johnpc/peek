import UIKit

/// The device clipboard, behind a protocol so sessions are testable without
/// touching `UIPasteboard.general` (which also triggers iOS's paste notice).
protocol Pasteboard: AnyObject {
    var string: String? { get set }
    var changeCount: Int { get }
}

final class SystemPasteboard: Pasteboard {
    var string: String? {
        get { UIPasteboard.general.hasStrings ? UIPasteboard.general.string : nil }
        set { UIPasteboard.general.string = newValue }
    }

    var changeCount: Int { UIPasteboard.general.changeCount }
}

final class MockPasteboard: Pasteboard {
    var string: String? { didSet { changeCount += 1 } }
    private(set) var changeCount = 0

    init(string: String? = nil) {
        self.string = string
        changeCount = string == nil ? 0 : 1  // `didSet` doesn't run during init
    }
}
