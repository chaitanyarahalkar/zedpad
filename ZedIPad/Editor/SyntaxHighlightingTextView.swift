import SwiftUI
import UIKit

struct SyntaxHighlightingTextView: UIViewRepresentable {
    @Binding var text: String
    let language: Language
    let theme: ZedTheme
    let fontSize: CGFloat
    let tabSize: Int
    let wordWrap: Bool
    var highlightRanges: [NSRange] = []
    var scrollToRange: NSRange? = nil

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
        applyWordWrap(to: tv)
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
        applyWordWrap(to: tv)

        // Scroll to match range if requested
        if let range = scrollToRange, range.location != NSNotFound,
           range.location + range.length <= tv.text.count {
            tv.scrollRangeToVisible(range)
        }
    }

    private func applyWordWrap(to tv: UITextView) {
        if wordWrap {
            tv.textContainer.widthTracksTextView = true
            tv.textContainer.size = CGSize(width: tv.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        } else {
            tv.textContainer.widthTracksTextView = false
            tv.textContainer.size = CGSize(width: 10_000, height: CGFloat.greatestFiniteMagnitude)
        }
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
            let nsRange = NSRange(token.range, in: text)
            attrs.addAttribute(.foregroundColor,
                value: UIColor(token.color),
                range: nsRange)
        }

        // Highlight find matches
        for range in highlightRanges {
            guard range.location != NSNotFound,
                  range.location + range.length <= text.count else { continue }
            attrs.addAttribute(.backgroundColor,
                value: UIColor.yellow.withAlphaComponent(0.4),
                range: range)
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

        // Auto-indent + Tab → spaces + bracket auto-close
        func textView(_ textView: UITextView,
                      shouldChangeTextIn range: NSRange,
                      replacementText text: String) -> Bool {
            // Tab key → insert spaces
            if text == "\t" {
                let spaces = String(repeating: " ", count: parent.tabSize)
                textView.insertText(spaces)
                return false
            }

            // Bracket/quote auto-closing
            let pairs: [String: String] = ["{": "}", "(": ")", "[": "]", "\"": "\"", "'": "'"]
            if let closing = pairs[text] {
                textView.insertText(text + closing)
                // Move cursor between the pair
                if let pos = textView.selectedTextRange {
                    let newPos = textView.position(from: pos.start, offset: -1)!
                    textView.selectedTextRange = textView.textRange(from: newPos, to: newPos)
                }
                return false
            }

            // Skip over closing bracket if already typed
            let closers: Set<String> = ["}", ")", "]", "\"", "'"]
            if closers.contains(text) {
                let nsText = textView.text as NSString
                if range.location < nsText.length {
                    let nextChar = nsText.substring(with: NSRange(location: range.location, length: 1))
                    if nextChar == text {
                        // Move cursor forward instead of inserting
                        if let pos = textView.selectedTextRange {
                            let newPos = textView.position(from: pos.start, offset: 1)!
                            textView.selectedTextRange = textView.textRange(from: newPos, to: newPos)
                        }
                        return false
                    }
                }
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
