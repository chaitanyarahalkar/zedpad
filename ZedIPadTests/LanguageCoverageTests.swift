import XCTest
@testable import ZedIPad

final class LanguageCoverageTests: XCTestCase {

    func testJavaScriptKeywords() {
        let hl = SyntaxHighlighter(theme: .dark)
        let keywords = ["const", "let", "var", "function", "return", "if", "else",
                        "for", "while", "class", "import", "export", "async", "await"]
        for kw in keywords {
            let code = "\(kw) x"
            let tokens = hl.highlight(code, language: .javascript)
            let found = tokens.contains { code[$0.range] == kw }
            XCTAssertTrue(found, "Keyword '\(kw)' not highlighted in JavaScript")
        }
    }

    func testPythonKeywords() {
        let hl = SyntaxHighlighter(theme: .dark)
        let keywords = ["def", "class", "import", "return", "if", "else", "for", "while"]
        for kw in keywords {
            let code = "\(kw) x"
            let tokens = hl.highlight(code, language: .python)
            let found = tokens.contains { code[$0.range] == kw }
            XCTAssertTrue(found, "Keyword '\(kw)' not highlighted in Python")
        }
    }

    func testRustKeywords() {
        let hl = SyntaxHighlighter(theme: .dark)
        let keywords = ["fn", "let", "mut", "struct", "enum", "impl", "pub", "if", "else", "return"]
        for kw in keywords {
            let code = "\(kw) x"
            let tokens = hl.highlight(code, language: .rust)
            let found = tokens.contains { code[$0.range] == kw }
            XCTAssertTrue(found, "Keyword '\(kw)' not highlighted in Rust")
        }
    }

    func testGoKeywords() {
        let hl = SyntaxHighlighter(theme: .dark)
        let keywords = ["func", "var", "const", "struct", "interface", "import", "package", "return"]
        for kw in keywords {
            let code = "\(kw) x"
            let tokens = hl.highlight(code, language: .go)
            let found = tokens.contains { code[$0.range] == kw }
            XCTAssertTrue(found, "Keyword '\(kw)' not highlighted in Go")
        }
    }

    func testKotlinKeywords() {
        let hl = SyntaxHighlighter(theme: .dark)
        let keywords = ["fun", "val", "var", "class", "interface", "object", "if", "else", "return"]
        for kw in keywords {
            let code = "\(kw) x"
            let tokens = hl.highlight(code, language: .kotlin)
            let found = tokens.contains { code[$0.range] == kw }
            XCTAssertTrue(found, "Keyword '\(kw)' not highlighted in Kotlin")
        }
    }

    func testSwiftKeywordsExhaustive() {
        let hl = SyntaxHighlighter(theme: .dark)
        let keywords = ["import", "struct", "class", "enum", "protocol", "func", "var", "let",
                        "if", "else", "guard", "return", "switch", "case", "for", "while",
                        "true", "false", "nil", "self", "static", "final", "override"]
        for kw in keywords {
            let code = "\(kw) x"
            let tokens = hl.highlight(code, language: .swift)
            let found = tokens.contains { code[$0.range] == kw }
            XCTAssertTrue(found, "Keyword '\(kw)' not highlighted in Swift")
        }
    }
}
