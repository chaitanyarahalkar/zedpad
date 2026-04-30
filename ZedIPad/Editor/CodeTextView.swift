import UIKit

/// UITextView subclass that adds standard editor key commands.
/// Key commands live here (on a UIResponder) rather than in the SwiftUI layer.
class CodeTextView: UITextView {

    var language: Language = .unknown
    var tabSize: Int = 4
    weak var editorDelegate: CodeTextViewDelegate?

    override var keyCommands: [UIKeyCommand]? {
        var cmds = super.keyCommands ?? []
        cmds += [
            // ─── Line operations ─────────────────────────────────────────
            cmd("L",       [.command],          #selector(selectLine),          "Select Line"),
            cmd("k",       [.command, .shift],  #selector(deleteLine),          "Delete Line"),
            cmd("\r",      [.command],          #selector(insertLineBelow),     "Insert Line Below"),
            cmd("\r",      [.command, .shift],  #selector(insertLineAbove),     "Insert Line Above"),

            // ─── Indentation ─────────────────────────────────────────────
            cmd("]",       [.command],          #selector(indentSelection),     "Indent"),
            cmd("[",       [.command],          #selector(outdentSelection),    "Outdent"),

            // ─── Comment toggle ──────────────────────────────────────────
            cmd("/",       [.command],          #selector(toggleComment),       "Toggle Comment"),

            // ─── Deletion ────────────────────────────────────────────────
            cmd("\u{08}",  [.command],          #selector(deleteToLineStart),   "Delete to Line Start"),
            cmd("\u{08}",  [.alternate],        #selector(deleteWordBackward),  "Delete Word Backward"),

            // ─── Save ────────────────────────────────────────────────────
            cmd("s",       [.command],          #selector(saveFile),            "Save"),

            // ─── Move lines ──────────────────────────────────────────────
            cmd(UIKeyCommand.inputUpArrow,   [.command, .alternate], #selector(moveLineUp),   "Move Line Up"),
            cmd(UIKeyCommand.inputDownArrow, [.command, .alternate], #selector(moveLineDown), "Move Line Down"),

            // ─── Duplicate line ──────────────────────────────────────────
            cmd("d",       [.command, .shift],  #selector(duplicateLine),       "Duplicate Line"),
        ]
        return cmds
    }

    private func cmd(_ key: String, _ modifiers: UIKeyModifierFlags,
                     _ selector: Selector, _ title: String) -> UIKeyCommand {
        UIKeyCommand(title: title, action: selector, input: key, modifierFlags: modifiers)
    }

    // MARK: - Actions

    @objc func selectLine() {
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let nsRange = NSRange(location: offset(from: beginningOfDocument, to: range.start), length: 0)
        let lineRange = nsText.lineRange(for: nsRange)
        if let start = position(from: beginningOfDocument, offset: lineRange.location),
           let end   = position(from: beginningOfDocument, offset: lineRange.location + lineRange.length) {
            selectedTextRange = textRange(from: start, to: end)
        }
    }

    @objc func deleteLine() {
        selectLine()
        guard let sel = selectedTextRange else { return }
        replace(sel, withText: "")
    }

    @objc func insertLineBelow() {
        // Move to end of current line, insert newline + same indent
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let offset = self.offset(from: beginningOfDocument, to: range.start)
        let lineRange = nsText.lineRange(for: NSRange(location: offset, length: 0))
        let lineEnd = lineRange.location + lineRange.length - (nsText.substring(with: lineRange).hasSuffix("\n") ? 1 : 0)
        if let endPos = position(from: beginningOfDocument, offset: lineEnd),
           let endRange = textRange(from: endPos, to: endPos) {
            selectedTextRange = endRange
        }
        let indent = leadingWhitespace(at: offset)
        insertText("\n" + indent)
    }

    @objc func insertLineAbove() {
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let offset = self.offset(from: beginningOfDocument, to: range.start)
        let lineRange = nsText.lineRange(for: NSRange(location: offset, length: 0))
        let indent = leadingWhitespace(at: offset)
        if let startPos = position(from: beginningOfDocument, offset: lineRange.location),
           let startRange = textRange(from: startPos, to: startPos) {
            selectedTextRange = startRange
        }
        insertText(indent + "\n")
        // Move cursor up one line
        if let pos = selectedTextRange {
            if let up = position(from: pos.start, offset: -(indent.count + 1)) {
                selectedTextRange = textRange(from: up, to: up)
            }
        }
    }

    @objc func indentSelection() {
        modifySelectedLines { $0.hasPrefix("\t") ? $0 : String(repeating: " ", count: tabSize) + $0 }
    }

    @objc func outdentSelection() {
        let spaces = String(repeating: " ", count: tabSize)
        modifySelectedLines { line in
            if line.hasPrefix(spaces) { return String(line.dropFirst(tabSize)) }
            if line.hasPrefix("\t")   { return String(line.dropFirst()) }
            return line
        }
    }

    @objc func toggleComment() {
        let prefix = commentPrefix(for: language)
        modifySelectedLines { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(prefix) {
                // Uncomment — remove first occurrence of prefix (preserving indent)
                if let r = line.range(of: prefix) {
                    var result = line
                    result.removeSubrange(r)
                    // Remove one space after prefix if present
                    if result[r.lowerBound...].hasPrefix(" ") {
                        result.remove(at: r.lowerBound)
                    }
                    return result
                }
            }
            // Comment — insert before first non-whitespace
            let ws = String(line.prefix(while: { $0 == " " || $0 == "\t" }))
            let rest = line.dropFirst(ws.count)
            return ws + prefix + " " + rest
        }
    }

    @objc func deleteToLineStart() {
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let cursorOff = offset(from: beginningOfDocument, to: range.start)
        let lineRange = nsText.lineRange(for: NSRange(location: cursorOff, length: 0))
        let count = cursorOff - lineRange.location
        if count > 0,
           let start = position(from: range.start, offset: -count),
           let delRange = textRange(from: start, to: range.start) {
            replace(delRange, withText: "")
        }
    }

    @objc func deleteWordBackward() {
        guard let range = selectedTextRange, range.isEmpty else { return }
        // Move back over whitespace then over word chars
        var offset = self.offset(from: beginningOfDocument, to: range.start)
        let nsText = text as NSString
        if offset == 0 { return }
        // skip whitespace
        while offset > 0 {
            let ch = nsText.character(at: offset - 1)
            let scalar = Unicode.Scalar(ch)!
            if CharacterSet.whitespaces.contains(scalar) { offset -= 1 } else { break }
        }
        // skip word chars
        while offset > 0 {
            let ch = nsText.character(at: offset - 1)
            let scalar = Unicode.Scalar(ch)!
            if CharacterSet.alphanumerics.union(.init(charactersIn: "_")).contains(scalar) {
                offset -= 1
            } else { break }
        }
        let cursorOff = self.offset(from: beginningOfDocument, to: range.start)
        let count = cursorOff - offset
        if count > 0,
           let start = position(from: range.start, offset: -count),
           let delRange = textRange(from: start, to: range.start) {
            replace(delRange, withText: "")
        }
    }

    @objc func saveFile() {
        editorDelegate?.codeTextViewRequestedSave(self)
    }

    @objc func moveLineUp() {
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let cursorOff = offset(from: beginningOfDocument, to: range.start)
        let lineRange = nsText.lineRange(for: NSRange(location: cursorOff, length: 0))
        guard lineRange.location > 0 else { return }
        let prevLineRange = nsText.lineRange(for: NSRange(location: lineRange.location - 1, length: 0))
        let currentLine = nsText.substring(with: lineRange)
        let prevLine    = nsText.substring(with: prevLineRange)
        // Swap
        let combined = NSRange(location: prevLineRange.location, length: prevLineRange.length + lineRange.length)
        if let r = textRange(from: position(from: beginningOfDocument, offset: combined.location)!,
                             to: position(from: beginningOfDocument, offset: combined.location + combined.length)!) {
            replace(r, withText: currentLine + prevLine)
            // Restore cursor on moved line
            if let pos = position(from: beginningOfDocument, offset: prevLineRange.location + cursorOff - lineRange.location) {
                selectedTextRange = textRange(from: pos, to: pos)
            }
        }
    }

    @objc func moveLineDown() {
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let cursorOff = offset(from: beginningOfDocument, to: range.start)
        let lineRange = nsText.lineRange(for: NSRange(location: cursorOff, length: 0))
        let nextStart = lineRange.location + lineRange.length
        guard nextStart < nsText.length else { return }
        let nextLineRange = nsText.lineRange(for: NSRange(location: nextStart, length: 0))
        let currentLine = nsText.substring(with: lineRange)
        let nextLine    = nsText.substring(with: nextLineRange)
        let combined = NSRange(location: lineRange.location, length: lineRange.length + nextLineRange.length)
        if let r = textRange(from: position(from: beginningOfDocument, offset: combined.location)!,
                             to: position(from: beginningOfDocument, offset: combined.location + combined.length)!) {
            replace(r, withText: nextLine + currentLine)
            let newOff = nextLineRange.location + cursorOff - lineRange.location
            if let pos = position(from: beginningOfDocument, offset: newOff) {
                selectedTextRange = textRange(from: pos, to: pos)
            }
        }
    }

    @objc func duplicateLine() {
        guard let range = selectedTextRange else { return }
        let nsText = text as NSString
        let cursorOff = offset(from: beginningOfDocument, to: range.start)
        let lineRange = nsText.lineRange(for: NSRange(location: cursorOff, length: 0))
        let line = nsText.substring(with: lineRange)
        let insertOffset = lineRange.location + lineRange.length
        if let pos = position(from: beginningOfDocument, offset: insertOffset),
           let insRange = textRange(from: pos, to: pos) {
            replace(insRange, withText: line.hasSuffix("\n") ? line : "\n" + line)
        }
    }

    // MARK: - Helpers

    private func leadingWhitespace(at offset: Int) -> String {
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: NSRange(location: offset, length: 0))
        let line = nsText.substring(with: lineRange)
        return String(line.prefix(while: { $0 == " " || $0 == "\t" }))
    }

    private func modifySelectedLines(transform: (String) -> String) {
        let sel = selectedRange
        let nsText = text as NSString
        let linesRange = nsText.lineRange(for: sel)
        let linesStr = nsText.substring(with: linesRange)
        var lines = linesStr.components(separatedBy: "\n")
        let trailingNewline = linesStr.hasSuffix("\n")
        if trailingNewline { lines.removeLast() }
        let transformed = lines.map(transform).joined(separator: "\n") + (trailingNewline ? "\n" : "")
        if let r = textRange(from: position(from: beginningOfDocument, offset: linesRange.location)!,
                             to: position(from: beginningOfDocument, offset: linesRange.location + linesRange.length)!) {
            replace(r, withText: transformed)
            // Restore selection in transformed region
            let newSel = NSRange(location: linesRange.location,
                                 length: min(sel.length, transformed.count))
            selectedRange = newSel
        }
    }

    private func commentPrefix(for language: Language) -> String {
        switch language {
        case .python, .ruby, .bash, .yaml: return "#"
        case .html: return "<!--"
        case .css: return "/*"
        case .sql: return "--"
        default: return "//"   // Swift, JS, TS, Rust, Go, Kotlin, C, C++, Java, Scala, Lua
        }
    }
}

@MainActor
protocol CodeTextViewDelegate: AnyObject {
    func codeTextViewRequestedSave(_ textView: CodeTextView)
}
