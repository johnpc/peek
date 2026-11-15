import SwiftUI
import UIKit

/// Hosts a SwiftUI view as the system keyboard's accessory, so UIKit keeps it
/// glued to the top of the keyboard (docked at the bottom with a hardware
/// keyboard) — none of SwiftUI's keyboard-avoidance guesswork, which left the
/// key bar floating mid-screen with a gap above the keys.
final class KeyboardAccessoryView<Content: View>: UIView {
    private let host: UIHostingController<Content>

    init(height: CGFloat, content: Content) {
        host = UIHostingController(rootView: content)
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: height))
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear
        host.view.backgroundColor = .clear
        host.safeAreaRegions = []
        host.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.view.topAnchor.constraint(equalTo: topAnchor),
            host.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { nil }

    func update(_ content: Content) { host.rootView = content }
}
