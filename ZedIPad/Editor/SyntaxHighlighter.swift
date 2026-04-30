import SwiftUI

struct SyntaxToken {
    let range: Range<String.Index>
    let color: Color
}

class SyntaxHighlighter {
    private let theme: ZedTheme

    init(theme: ZedTheme) {
        self.theme = theme
    }

    func highlight(_ text: String, language: Language) -> [SyntaxToken] {
        switch language {
        case .swift: return highlightSwift(text)
        case .javascript, .typescript: return highlightJS(text)
        case .python: return highlightPython(text)
        case .rust: return highlightRust(text)
        case .markdown: return highlightMarkdown(text)
        case .json: return highlightJSON(text)
        case .yaml: return highlightYAML(text)
        case .bash: return highlightBash(text)
        case .ruby: return highlightRuby(text)
        case .html: return highlightHTML(text)
        case .css: return highlightCSS(text)
        case .unknown: return []
        }
    }

    private func highlightSwift(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["import", "struct", "class", "enum", "protocol", "extension",
                        "func", "var", "let", "if", "else", "guard", "return", "switch",
                        "case", "default", "for", "in", "while", "do", "try", "catch",
                        "throw", "throws", "async", "await", "actor", "nonisolated",
                        "public", "private", "internal", "fileprivate", "open",
                        "static", "final", "override", "init", "deinit", "self", "Self",
                        "true", "false", "nil", "where", "as", "is", "inout", "mutating",
                        "@Published", "@State", "@Binding", "@ObservedObject", "@StateObject",
                        "@EnvironmentObject", "@MainActor", "@discardableResult"]
        let types = ["String", "Int", "Double", "Float", "Bool", "Array", "Dictionary",
                     "Set", "Optional", "Any", "AnyObject", "Void", "Never", "UUID",
                     "Date", "Data", "URL", "Error", "View", "Color", "Font",
                     "ObservableObject", "Identifiable"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightJS(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["const", "let", "var", "function", "return", "if", "else",
                        "for", "while", "do", "switch", "case", "break", "continue",
                        "import", "export", "default", "class", "extends", "new",
                        "this", "super", "typeof", "instanceof", "in", "of",
                        "async", "await", "try", "catch", "throw", "null", "undefined",
                        "true", "false", "from", "interface", "type", "enum"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightPython(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["def", "class", "import", "from", "return", "if", "elif", "else",
                        "for", "while", "in", "not", "and", "or", "is", "None", "True",
                        "False", "try", "except", "finally", "raise", "with", "as",
                        "pass", "break", "continue", "lambda", "yield", "async", "await",
                        "global", "nonlocal", "del", "assert"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeStrings(text)
        tokens += tokenizeHashComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightRust(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["fn", "let", "mut", "const", "static", "struct", "enum", "trait",
                        "impl", "use", "mod", "pub", "priv", "if", "else", "match",
                        "for", "while", "loop", "return", "break", "continue", "in",
                        "where", "type", "self", "Self", "super", "crate", "extern",
                        "unsafe", "async", "await", "move", "ref", "true", "false", "dyn"]
        let types = ["String", "str", "i32", "i64", "u32", "u64", "f32", "f64", "bool",
                     "usize", "isize", "Vec", "HashMap", "Option", "Result", "Box",
                     "Arc", "Rc", "Cell", "RefCell"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightMarkdown(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let lines = text.components(separatedBy: "\n")
        var currentIndex = text.startIndex
        for line in lines {
            guard let lineRange = text.range(of: line, range: currentIndex..<text.endIndex) else {
                if currentIndex < text.endIndex {
                    currentIndex = text.index(after: currentIndex)
                }
                continue
            }
            if line.hasPrefix("#") {
                tokens.append(SyntaxToken(range: lineRange, color: theme.syntaxFunction))
            } else if line.hasPrefix("```") || line.hasPrefix("    ") {
                tokens.append(SyntaxToken(range: lineRange, color: theme.secondaryText))
            }
            currentIndex = lineRange.upperBound
            if currentIndex < text.endIndex {
                currentIndex = text.index(after: currentIndex)
            }
        }
        tokens += tokenizeStrings(text)
        return tokens
    }

    private func highlightJSON(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        tokens += tokenizeStrings(text)
        tokens += tokenizeNumbers(text)
        let keywords = ["true", "false", "null"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        return tokens
    }

    private func highlightYAML(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        // YAML keys: word before colon
        let keyPattern = "^[ \\t]*([a-zA-Z_][a-zA-Z0-9_\\-]*)[ \\t]*:"
        if let regex = try? NSRegularExpression(pattern: keyPattern, options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxFunction))
                }
            }
        }
        tokens += tokenizeStrings(text)
        tokens += tokenizeHashComments(text)
        tokens += tokenizeNumbers(text)
        let boolKeywords = ["true", "false", "null", "yes", "no", "on", "off"]
        tokens += tokenizeKeywords(text, keywords: boolKeywords, color: theme.syntaxKeyword)
        return tokens
    }

    private func highlightBash(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["if", "then", "else", "elif", "fi", "for", "do", "done", "while",
                        "case", "esac", "in", "function", "return", "exit", "local",
                        "export", "source", "echo", "printf", "read", "set", "unset",
                        "true", "false", "break", "continue", "shift", "trap"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeStrings(text)
        tokens += tokenizeHashComments(text)
        tokens += tokenizeNumbers(text)
        // Variables: $VAR or ${VAR}
        let varPattern = "\\$\\{?[a-zA-Z_][a-zA-Z0-9_]*\\}?"
        if let regex = try? NSRegularExpression(pattern: varPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxType))
                }
            }
        }
        return tokens
    }

    private func highlightRuby(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["def", "class", "module", "end", "do", "if", "elsif", "else",
                        "unless", "while", "until", "for", "in", "return", "yield",
                        "begin", "rescue", "ensure", "raise", "require", "require_relative",
                        "include", "extend", "attr_accessor", "attr_reader", "attr_writer",
                        "true", "false", "nil", "self", "super", "puts", "print", "p",
                        "lambda", "proc", "and", "or", "not", "then", "when", "case"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeStrings(text)
        tokens += tokenizeHashComments(text)
        tokens += tokenizeNumbers(text)
        // Symbols: :foo
        let symbolPattern = ":[a-zA-Z_][a-zA-Z0-9_]*"
        if let regex = try? NSRegularExpression(pattern: symbolPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxType))
                }
            }
        }
        return tokens
    }

    private func highlightHTML(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        // Tags: <tag> </tag>
        let tagPattern = "</?[a-zA-Z][a-zA-Z0-9]*(?:[^>]*)?>?"
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxKeyword))
                }
            }
        }
        // Attributes: name="value"
        let attrPattern = "[a-zA-Z\\-]+=\"[^\"]*\""
        if let regex = try? NSRegularExpression(pattern: attrPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxString))
                }
            }
        }
        // Comments
        let commentPattern = "<!--[\\s\\S]*?-->"
        if let regex = try? NSRegularExpression(pattern: commentPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxComment))
                }
            }
        }
        return tokens
    }

    private func highlightCSS(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        // Properties: property:
        let propPattern = "[a-zA-Z\\-]+(?=\\s*:)"
        if let regex = try? NSRegularExpression(pattern: propPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxFunction))
                }
            }
        }
        // Values after colon
        let valuePattern = ":\\s*([^;{}\n]+);"
        if let regex = try? NSRegularExpression(pattern: valuePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxString))
                }
            }
        }
        // Selectors: .class, #id, tag
        let selectorPattern = "^[ \\t]*([.#]?[a-zA-Z][a-zA-Z0-9_\\-]*)[ \\t]*\\{"
        if let regex = try? NSRegularExpression(pattern: selectorPattern, options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range(at: 1), in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxType))
                }
            }
        }
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    // MARK: - Tokenizers

    private func tokenizeKeywords(_ text: String, keywords: [String], color: Color) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        for keyword in keywords {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: color))
                }
            }
        }
        return tokens
    }

    private func tokenizeStrings(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let patterns = ["\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\"", "'[^'\\\\]*(?:\\\\.[^'\\\\]*)*'"]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else { continue }
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxString))
                }
            }
        }
        return tokens
    }

    private func tokenizeComments(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        // Single line //
        let linePattern = "//[^\n]*"
        if let regex = try? NSRegularExpression(pattern: linePattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxComment))
                }
            }
        }
        // Block /* */
        let blockPattern = "/\\*[\\s\\S]*?\\*/"
        if let regex = try? NSRegularExpression(pattern: blockPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxComment))
                }
            }
        }
        return tokens
    }

    private func tokenizeHashComments(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let pattern = "#[^\n]*"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            if let range = Range(match.range, in: text) {
                tokens.append(SyntaxToken(range: range, color: theme.syntaxComment))
            }
        }
        return tokens
    }

    private func tokenizeNumbers(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let pattern = "\\b\\d+(\\.\\d+)?\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        for match in matches {
            if let range = Range(match.range, in: text) {
                tokens.append(SyntaxToken(range: range, color: theme.syntaxNumber))
            }
        }
        return tokens
    }
}

enum Language: String {
    case swift, javascript, typescript, python, rust, markdown, json, yaml, bash, ruby, html, css, unknown

    static func detect(from extension: String) -> Language {
        switch `extension`.lowercased() {
        case "swift": return .swift
        case "js": return .javascript
        case "ts", "tsx", "jsx": return .typescript
        case "py": return .python
        case "rs": return .rust
        case "md": return .markdown
        case "json": return .json
        case "yaml", "yml": return .yaml
        case "sh", "bash": return .bash
        case "rb": return .ruby
        case "html", "htm": return .html
        case "css": return .css
        default: return .unknown
        }
    }
}
