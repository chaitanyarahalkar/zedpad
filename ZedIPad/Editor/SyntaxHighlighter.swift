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
        case .go: return highlightGo(text)
        case .kotlin: return highlightKotlin(text)
        case .c: return highlightC(text)
        case .cpp: return highlightCpp(text)
        case .sql: return highlightSQL(text)
        case .scala: return highlightScala(text)
        case .lua: return highlightLua(text)
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

    private func highlightGo(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["package", "import", "func", "var", "const", "type", "struct",
                        "interface", "map", "chan", "go", "defer", "select", "case",
                        "default", "if", "else", "for", "range", "return", "break",
                        "continue", "fallthrough", "goto", "switch", "nil", "true", "false",
                        "make", "new", "append", "len", "cap", "delete", "copy", "close",
                        "panic", "recover", "error"]
        let types = ["int", "int8", "int16", "int32", "int64", "uint", "uint8", "uint16",
                     "uint32", "uint64", "float32", "float64", "complex64", "complex128",
                     "bool", "byte", "rune", "string", "uintptr", "any"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightKotlin(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["fun", "val", "var", "class", "object", "interface", "enum",
                        "data", "sealed", "abstract", "open", "override", "final",
                        "private", "protected", "public", "internal", "companion",
                        "if", "else", "when", "for", "while", "do", "return", "break",
                        "continue", "throw", "try", "catch", "finally", "import", "package",
                        "as", "in", "is", "null", "true", "false", "this", "super",
                        "by", "init", "constructor", "get", "set", "lateinit", "lazy",
                        "suspend", "coroutine", "flow", "launch", "async", "await"]
        let types = ["String", "Int", "Long", "Double", "Float", "Boolean", "Char",
                     "Byte", "Short", "Unit", "Any", "Nothing", "List", "Map", "Set",
                     "Array", "Pair", "Triple", "Result"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightC(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["auto", "break", "case", "char", "const", "continue", "default",
                        "do", "double", "else", "enum", "extern", "float", "for", "goto",
                        "if", "inline", "int", "long", "register", "return", "short",
                        "signed", "sizeof", "static", "struct", "switch", "typedef",
                        "union", "unsigned", "void", "volatile", "while", "NULL",
                        "#include", "#define", "#ifdef", "#ifndef", "#endif", "#pragma"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        // Preprocessor directives
        let ppPattern = "^#[a-zA-Z_]+"
        if let regex = try? NSRegularExpression(pattern: ppPattern, options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxType))
                }
            }
        }
        return tokens
    }

    private func highlightCpp(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["auto", "bool", "break", "case", "catch", "char", "class", "const",
                        "constexpr", "continue", "default", "delete", "do", "double",
                        "else", "enum", "explicit", "export", "extern", "false", "float",
                        "for", "friend", "goto", "if", "inline", "int", "long", "mutable",
                        "namespace", "new", "noexcept", "nullptr", "operator", "override",
                        "private", "protected", "public", "return", "short", "sizeof",
                        "static", "static_assert", "static_cast", "struct", "switch",
                        "template", "this", "throw", "true", "try", "typedef", "typeid",
                        "typename", "union", "using", "virtual", "void", "volatile", "while"]
        let types = ["string", "vector", "map", "set", "unordered_map", "unordered_set",
                     "list", "deque", "queue", "stack", "pair", "tuple", "optional",
                     "variant", "any", "shared_ptr", "unique_ptr", "weak_ptr",
                     "size_t", "int8_t", "int16_t", "int32_t", "int64_t",
                     "uint8_t", "uint16_t", "uint32_t", "uint64_t"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightSQL(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["SELECT", "FROM", "WHERE", "JOIN", "LEFT", "RIGHT", "INNER", "OUTER",
                        "ON", "AS", "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE",
                        "CREATE", "TABLE", "DROP", "ALTER", "ADD", "COLUMN", "INDEX",
                        "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "UNIQUE", "NOT", "NULL",
                        "DEFAULT", "AUTO_INCREMENT", "CONSTRAINT", "CHECK", "AND", "OR",
                        "IN", "LIKE", "BETWEEN", "EXISTS", "CASE", "WHEN", "THEN", "ELSE",
                        "END", "GROUP", "BY", "ORDER", "HAVING", "LIMIT", "OFFSET",
                        "DISTINCT", "ALL", "UNION", "INTERSECT", "EXCEPT",
                        "BEGIN", "COMMIT", "ROLLBACK", "TRANSACTION",
                        "select", "from", "where", "join", "left", "right", "inner",
                        "insert", "into", "values", "update", "set", "delete",
                        "create", "table", "drop", "alter", "add"]
        let types = ["INT", "INTEGER", "BIGINT", "SMALLINT", "TINYINT", "FLOAT", "DOUBLE",
                     "DECIMAL", "NUMERIC", "VARCHAR", "CHAR", "TEXT", "BLOB", "DATE",
                     "DATETIME", "TIMESTAMP", "BOOLEAN", "BOOL", "SERIAL",
                     "int", "varchar", "text", "boolean", "date", "timestamp"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeNumbers(text)
        // SQL comments: -- and /* */
        let lineCommentPattern = "--[^\n]*"
        if let regex = try? NSRegularExpression(pattern: lineCommentPattern) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxComment))
                }
            }
        }
        tokens += tokenizeComments(text) // block comments
        return tokens
    }

    private func highlightScala(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["abstract", "case", "catch", "class", "def", "do", "else", "extends",
                        "false", "final", "finally", "for", "forSome", "if", "implicit",
                        "import", "lazy", "match", "new", "null", "object", "override",
                        "package", "private", "protected", "return", "sealed", "super",
                        "this", "throw", "trait", "try", "true", "type", "val", "var",
                        "while", "with", "yield", "given", "using", "enum", "extension",
                        "inline", "opaque", "transparent"]
        let types = ["Int", "Long", "Double", "Float", "Boolean", "Char", "Byte", "Short",
                     "String", "Unit", "Any", "AnyRef", "AnyVal", "Nothing", "Null",
                     "List", "Map", "Set", "Seq", "Option", "Some", "None", "Either",
                     "Future", "Try", "Success", "Failure"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeKeywords(text, keywords: types, color: theme.syntaxType)
        tokens += tokenizeStrings(text)
        tokens += tokenizeComments(text)
        tokens += tokenizeNumbers(text)
        return tokens
    }

    private func highlightLua(_ text: String) -> [SyntaxToken] {
        var tokens: [SyntaxToken] = []
        let keywords = ["and", "break", "do", "else", "elseif", "end", "false", "for",
                        "function", "goto", "if", "in", "local", "nil", "not", "or",
                        "repeat", "return", "then", "true", "until", "while",
                        "require", "print", "type", "pairs", "ipairs", "next",
                        "pcall", "error", "assert", "tostring", "tonumber",
                        "table", "string", "math", "os", "io", "coroutine"]
        tokens += tokenizeKeywords(text, keywords: keywords, color: theme.syntaxKeyword)
        tokens += tokenizeStrings(text)
        tokens += tokenizeHashComments(text) // -- is Lua line comment
        tokens += tokenizeNumbers(text)
        // -- comment (Lua uses --)
        let luaComment = "--[^\n]*"
        if let regex = try? NSRegularExpression(pattern: luaComment) {
            let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    tokens.append(SyntaxToken(range: range, color: theme.syntaxComment))
                }
            }
        }
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
    case swift, javascript, typescript, python, rust, markdown, json, yaml, bash, ruby, html, css, go, kotlin, c, cpp, sql, scala, lua, unknown

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
        case "go": return .go
        case "kt", "kts": return .kotlin
        case "c", "h": return .c
        case "cpp", "cc", "cxx", "hpp", "hxx": return .cpp
        case "sql": return .sql
        case "scala", "sc": return .scala
        case "lua": return .lua
        default: return .unknown
        }
    }
}
