import SwiftUI
import UIKit

/// An invisible first responder that brings up the system keyboard and turns
/// typed characters into remote key presses.
struct KeyInputView: UIViewRepresentable {
    let isActive: Bool
    let onText: (String) -> Void
    let onBackspace: () -> Void
    let onReturn: () -> Void
    var onHardwareKey: (HardwareKeyAction) -> Void = { _ in }
    /// Rides on top of the system keyboard (the key bar).
    var accessory: AnyView? = nil

    func makeUIView(context: Context) -> KeyInputUIView {
        let view = KeyInputUIView()
        if let accessory { view.accessoryHost = KeyboardAccessoryView(height: KeyboardBar.height, content: accessory) }
        view.onText = onText
        view.onBackspace = onBackspace
        view.onReturn = onReturn
        view.onHardwareKey = onHardwareKey
        return view
    }

    func updateUIView(_ uiView: KeyInputUIView, context: Context) {
        uiView.onText = onText
        uiView.onBackspace = onBackspace
        uiView.onReturn = onReturn
        uiView.onHardwareKey = onHardwareKey
        if let accessory { uiView.accessoryHost?.update(accessory) }
        if isActive, !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        } else if !isActive, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
}

final class KeyInputUIView: UIView, UIKeyInput {
    var onText: ((String) -> Void)?
    var onBackspace: (() -> Void)?
    var onReturn: (() -> Void)?
    var onHardwareKey: ((HardwareKeyAction) -> Void)?
    var accessoryHost: KeyboardAccessoryView<AnyView>?

    override var canBecomeFirstResponder: Bool { true }
    override var inputAccessoryView: UIView? { accessoryHost }
    var hasText: Bool { true }
    var autocorrectionType: UITextAutocorrectionType = .no
    var autocapitalizationType: UITextAutocapitalizationType = .none
    var spellCheckingType: UITextSpellCheckingType = .no
    var smartQuotesType: UITextSmartQuotesType = .no
    var smartDashesType: UITextSmartDashesType = .no

    func insertText(_ text: String) {
        if text == "\n" {
            onReturn?()
        } else {
            onText?(text)
        }
    }

    func deleteBackward() {
        onBackspace?()
    }

    /// Physical keyboards: claim arrows/Esc/Tab and ⌘⌃⌥ chords here; let
    /// plain characters fall through to `insertText`.
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var unhandled: Set<UIPress> = []
        for press in presses {
            if let key = press.key, let action = handle(keyCode: key.keyCode, modifiers: key.modifierFlags,
                                                        characters: key.charactersIgnoringModifiers) {
                onHardwareKey?(action)
            } else {
                unhandled.insert(press)
            }
        }
        if !unhandled.isEmpty { super.pressesBegan(unhandled, with: event) }
    }

    func handle(keyCode: UIKeyboardHIDUsage, modifiers: UIKeyModifierFlags, characters: String) -> HardwareKeyAction? {
        HardwareKeyMap.action(keyCode: keyCode, modifiers: modifiers, characters: characters)
    }
}
