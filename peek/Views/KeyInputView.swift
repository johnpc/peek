import SwiftUI
import UIKit

/// An invisible first responder that brings up the system keyboard and turns
/// typed characters into remote key presses.
struct KeyInputView: UIViewRepresentable {
    let isActive: Bool
    let onText: (String) -> Void
    let onBackspace: () -> Void
    let onReturn: () -> Void

    func makeUIView(context: Context) -> KeyInputUIView {
        let view = KeyInputUIView()
        view.onText = onText
        view.onBackspace = onBackspace
        view.onReturn = onReturn
        return view
    }

    func updateUIView(_ uiView: KeyInputUIView, context: Context) {
        uiView.onText = onText
        uiView.onBackspace = onBackspace
        uiView.onReturn = onReturn
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

    override var canBecomeFirstResponder: Bool { true }
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
}
