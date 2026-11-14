import SwiftUI

/// Modifier and special keys the phone keyboard lacks. Modifiers are sticky
/// (see `ModifierLogic`); a held one is highlighted.
struct KeyboardBar: View {
    @ObservedObject var session: VNCSession

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Modifier.allCases, id: \.self) { modifier in
                    let held = session.heldModifiers.contains(modifier)
                    Button(modifier.symbol) { session.toggle(modifier) }
                        .buttonStyle(KeyButtonStyle(highlighted: held))
                        .accessibilityIdentifier("key-\(modifier.symbol)")
                        .accessibilityValue(held ? "held" : "released")
                }
                Divider().frame(height: 24)
                ForEach(RemoteKey.allCases, id: \.self) { key in
                    Button(key.label) { session.press(key) }
                        .buttonStyle(KeyButtonStyle(highlighted: false))
                        .accessibilityIdentifier("key-\(key.label)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

struct KeyButtonStyle: ButtonStyle {
    let highlighted: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.monospaced())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(highlighted ? Color.accentColor : Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(highlighted ? Color.white : Color.primary)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
