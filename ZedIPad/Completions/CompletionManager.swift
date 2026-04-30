import Foundation
import SwiftUI

@MainActor
class CompletionManager: ObservableObject {
    @Published var items: [CompletionItem] = []
    @Published var isVisible: Bool = false
    @Published var selectedIndex: Int = 0
    @Published var cursorRect: CGRect = .zero

    private let swiftProvider = SwiftCompletionProvider()
    private let jsProvider = JSCompletionProvider()
    private let genericProvider = GenericCompletionProvider()

    private var debounceTask: Task<Void, Never>?
    var mruBoosts: [String: Int] = [:]  // label → accepted count (internal for testing)

    func requestDebounced(source: String, cursorOffset: Int, language: Language, delay: Double = 0.2) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            if !Task.isCancelled {
                request(source: source, cursorOffset: cursorOffset, language: language)
            }
        }
    }

    func request(source: String, cursorOffset: Int, language: Language) {
        let prefix = extractPrefix(source: source, at: cursorOffset)
        guard prefix.count >= 1 else { dismiss(); return }

        var results: [CompletionItem]
        switch language {
        case .swift:
            results = swiftProvider.completions(source: source, prefix: prefix)
        case .javascript, .typescript:
            results = jsProvider.completions(source: source, prefix: prefix)
        default:
            results = genericProvider.completions(source: source, prefix: prefix, language: language)
        }

        // Apply MRU boost
        results = results.map { item in
            var boosted = item
            boosted.score += (mruBoosts[item.label] ?? 0) * 10
            return boosted
        }

        items = Array(results.sorted { $0.score > $1.score }.prefix(12))
        isVisible = !items.isEmpty
        selectedIndex = 0
    }

    func dismiss() {
        debounceTask?.cancel()
        isVisible = false
        items = []
    }

    func selectNext() {
        guard !items.isEmpty else { return }
        selectedIndex = min(selectedIndex + 1, items.count - 1)
    }

    func selectPrev() {
        guard !items.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
    }

    var selected: CompletionItem? {
        guard !items.isEmpty, selectedIndex < items.count else { return nil }
        return items[selectedIndex]
    }

    func acceptSelected(in textView: UITextView) {
        guard let item = selected else { return }
        accept(item: item, in: textView)
    }

    func accept(item: CompletionItem, in textView: UITextView) {
        mruBoosts[item.label, default: 0] += 1

        let currentText = textView.text ?? ""
        let cursorPos = textView.selectedRange.location
        let prefix = extractPrefix(source: currentText, at: cursorPos)

        // Build the UITextRange for the prefix so replace(_:withText:) fires textViewDidChange
        let prefixStart = cursorPos - prefix.count
        guard let start = textView.position(from: textView.beginningOfDocument, offset: prefixStart),
              let end = textView.position(from: textView.beginningOfDocument, offset: cursorPos),
              let uiRange = textView.textRange(from: start, to: end) else {
            dismiss()
            return
        }

        // replace(_:withText:) goes through the normal text pipeline → triggers textViewDidChange
        // → updates the @Binding → SwiftUI state stays in sync
        textView.replace(uiRange, withText: item.insertText)

        // Position cursor at end of inserted text
        let newCursorPos = prefixStart + item.insertText.count
        if let newPos = textView.position(from: textView.beginningOfDocument, offset: newCursorPos),
           let newRange = textView.textRange(from: newPos, to: newPos) {
            textView.selectedTextRange = newRange
        }

        dismiss()
    }

    func extractPrefix(source: String, at offset: Int) -> String {
        let safeOffset = min(offset, source.count)
        let idx = source.index(source.startIndex, offsetBy: safeOffset)
        var start = idx
        while start > source.startIndex {
            let prev = source.index(before: start)
            let ch = source[prev]
            if ch.isLetter || ch.isNumber || ch == "_" { start = prev } else { break }
        }
        return String(source[start..<idx])
    }
}
