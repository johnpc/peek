import UIKit

/// When the keyboard covers part of the view, the remote screen fits into the
/// part still visible, so what you are typing into is never under the keys.
extension RemoteScreenScrollView {
    func observeKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc func keyboardWillChangeFrame(_ note: Notification) {
        guard window != nil,
              let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        setKeyboardOverlap(Self.obscuredHeight(viewport: bounds, keyboard: convert(end, from: nil)), duration: duration)
    }

    /// How much of the viewport's bottom the keyboard hides (0 when it is away).
    static func obscuredHeight(viewport: CGRect, keyboard: CGRect) -> CGFloat {
        let overlap = viewport.intersection(keyboard)
        return overlap.isNull || overlap.isEmpty ? 0 : max(0, viewport.maxY - overlap.minY)
    }

    func setKeyboardOverlap(_ overlap: CGFloat, duration: Double) {
        guard overlap != keyboardOverlap else { return }
        keyboardOverlap = overlap
        UIView.animate(withDuration: duration) { self.layoutIfNeeded() }
    }
}
