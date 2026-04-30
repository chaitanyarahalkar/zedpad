import SwiftUI
import UIKit

struct SyntaxHighlightingTextView: UIViewRepresentable {
    @Binding var text: String
    let language: Language
    let theme: ZedTheme
    let fontSize: CGFloat
    let tabSize: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.isEditable = true
        tv.isScrollEnabled = true
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.smartInsertDeleteType = .no
        tv.spellCheckingType = .no
        tv.keyboardType = .asciiCapable
        tv.typingAttributes = context.coordinator.baseAttributes()
        applyHighlighting(to: tv, text: text)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.parent = self
        // Only re-apply if text changed externally (not from this view's own edits)
        if tv.text != text {
            let selectedRange = tv.selectedRange
            applyHighlighting(to: tv, text: text)
            // Restore cursor position
            let safeRange = NSRange(
                location: min(selectedRange.location, tv.text.count),
                length: 0
            )
            tv.selectedRange = safeRange
        }
        // Always keep typing attributes in sync with theme/font changes
        tv.typingAttributes = context.coordinator.baseAttributes()
    }

    func applyHighlighting(to tv: UITextView, text: String) {
        let highlighter = SyntaxHighlighter(theme: theme)
        let tokens = highlighter.highlight(text, language: language)

        let attrs = NSMutableAttributedString(string: text)
        let fullRange = NSRange(text.startIndex..., in: text)

        // Base style
        attrs.addAttribute(.font,
            value: UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            range: fullRange)
        attrs.addAttribute(.foregroundColor,
            value: UIColor(theme.primaryText),
            range: fullRange)

        // Apply syntax tokens
        for token in tokens {
            guard let nsRange = NSRange(token.range, in: text) else { continue }
            attrs.addAttribute(.foregroundColor,
                value: UIColor(token.color),
                range: nsRange)
        }

        tv.attributedText = attrs
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SyntaxHighlightingTextView
        private var highlightWorkItem: DispatchWorkItem?

        init(_ parent: SyntaxHighlightingTextView) {
            self.parent = parent
        }

        func baseAttributes() -> [NSAttributedString.Key: Any] {
            [
                .font: UIFont.monospacedSystemFont(ofSize: parent.fontSize, weight: .regular),
                .foregroundColor: UIColor(parent.theme.primaryText)
            ]
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text

            // Debounced highlight re-apply (300ms)
            highlightWorkItem?.cancel()
            let item = DispatchWorkItem { [weak self, weak textView] in
                guard let self, let textView else { return }
                let text = textView.text ?? ""
                let selectedRange = textView.selectedRange
                self.parent.applyHighlighting(to: textView, text: text)
                let safeRange = NSRange(
                    location: min(selectedRange.location, textView.text.count),
                    length: 0
                )
                textView.selectedRange = safeRange
            }
            highlightWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
        }

        // Auto-indent + Tab → spaces
        func textView(_ textView: UITextView,
                      shouldChangeTextIn range: NSRange,
                      replacementText text: String) -> Bool {
            // Tab key → insert spaces
            if text == "\t" {
                let spaces = String(repeating: " ", count: parent.tabSize)
                textView.insertText(spaces)
                return false
            }

            // Enter → auto-indent
            if text == "\n" {
                let nsText = textView.text as NSString
                // Find start of current line
                let lineRange = nsText.lineRange(for: NSRange(location: range.location, length: 0))
                let currentLine = nsText.substring(with: lineRange)

                // Extract leading whitespace
                var leadingWhitespace = ""
                for char in currentLine {
                    if char == " " || char == "\t" {
                        leadingWhitespace.append(char)
                    } else {
                        break
                    }
                }

                // Insert newline + same indent
                textView.insertText("\n" + leadingWhitespace)
                return false
            }

            return true
        }
    }
}
