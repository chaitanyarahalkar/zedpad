import XCTest
@testable import ZedIPad

final class HighlightEdgeCaseTests: XCTestCase {
    private let hl = SyntaxHighlighter(theme: .dark)

    func testHighlightTabsAndSpaces() {
        let code = "\tlet x = 1\n    let y = 2"
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens // no crash
    }

    func testHighlightWindowsLineEndings() {
        let code = "let x = 1\r\nlet y = 2\r\nlet z = 3"
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testHighlightMixedLineEndings() {
        let code = "line1\nline2\r\nline3\rline4"
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testHighlightNestedComments() {
        let code = "/* outer /* inner */ still outer */ let x = 1"
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testHighlightStringWithEscapes() {
        let code = "let s = \"line1\\nline2\\ttabbed\\\"quoted\\\"\""
        let tokens = hl.highlight(code, language: .swift)
        let strTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxString }
        XCTAssertFalse(strTokens.isEmpty)
    }

    func testHighlightMultipleStringsOnOneLine() {
        let code = "let a = \"foo\", b = \"bar\", c = \"baz\""
        let tokens = hl.highlight(code, language: .swift)
        let strTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxString }
        XCTAssertGreaterThan(strTokens.count, 0)
    }

    func testHighlightNumbersVariousFormats() {
        let code = "let a = 42, b = 3.14, c = 100_000, d = 0xFF"
        let tokens = hl.highlight(code, language: .swift)
        let numTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxNumber }
        XCTAssertGreaterThan(numTokens.count, 0)
    }

    func testHighlightAllZeroBytes() {
        let code = "let zero: UInt8 = 0x00"
        let tokens = hl.highlight(code, language: .swift)
        _ = tokens
    }

    func testHighlightCodeWithNoBraces() {
        let code = "let x = 1\nlet y = 2\nlet z = x + y"
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightSingleCharacterCode() {
        let chars = ["a", "1", "\"", "#", "/", "*", ".", "{", "}", ";"]
        for c in chars {
            let tokens = hl.highlight(c, language: .swift)
            _ = tokens
        }
    }
}
