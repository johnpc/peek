import SwiftUI

/// Keys the phone keyboard lacks. Page one: sticky ⌘⌥⌃⇧, Paste, esc/tab/
/// return/delete/arrows. Page two: F1–F12. A "Mac" menu holds common actions.
struct KeyboardBar: View {
    @ObservedObject var session: VNCSession
    @State private var showFunctionKeys = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Color.clear.frame(width: 1).id("start")
                    if showFunctionKeys {
                    ForEach(KeyChord.functionKeys) { key in
                        Button(key.label) { session.send(key) }
                            .buttonStyle(KeyButtonStyle(highlighted: false))
                            .accessibilityIdentifier("key-\(key.label)")
                    }
                } else {
                    mainKeys
                }
                Divider().frame(height: 24)
                Button(showFunctionKeys ? "ABC" : "F1–F12") {
                    showFunctionKeys.toggle()
                    // A new page starts at its first key, not wherever the old one was scrolled.
                    withAnimation { proxy.scrollTo("start", anchor: .leading) }
                }
                    .buttonStyle(KeyButtonStyle(highlighted: showFunctionKeys))
                    .accessibilityIdentifier("key-page")
                Menu {
                    ForEach(KeyChord.macActions) { action in
                        Button(action.label) { session.send(action) }
                    }
                } label: {
                    Label("Mac", systemImage: "apple.logo")
                }
                .buttonStyle(KeyButtonStyle(highlighted: false))
                .accessibilityIdentifier("key-Mac")
            }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .accessibilityIdentifier("keyboardBar")
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder private var mainKeys: some View {
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
        Divider().frame(height: 24)
        Button("Paste", systemImage: "doc.on.clipboard") { session.pasteFromDevice() }
            .buttonStyle(KeyButtonStyle(highlighted: false))
            .labelStyle(.titleAndIcon)
            .accessibilityIdentifier("key-Paste")
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
