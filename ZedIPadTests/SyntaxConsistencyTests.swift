import XCTest
@testable import ZedIPad

final class SyntaxConsistencyTests: XCTestCase {

    private let themes = ZedTheme.allCases
    private let hl = SyntaxHighlighter(theme: .dark)

    // Same code, different themes — token count should be equal
    func testSwiftTokenCountConsistentAcrossThemes() {
        let code = "import Foundation\nlet x: Int = 42\nfunc hello() { print(\"world\") }"
        let counts = themes.map { theme -> Int in
            let h = SyntaxHighlighter(theme: theme)
            return h.highlight(code, language: .swift).count
        }
        let first = counts[0]
        for count in counts { XCTAssertEqual(count, first, "Token count varies across themes") }
    }

    func testPythonTokenCountConsistentAcrossThemes() {
        let code = "def foo(x):\n    # comment\n    return x * 2\n\nresult = foo(21)"
        let counts = themes.map { theme -> Int in
            let h = SyntaxHighlighter(theme: theme)
            return h.highlight(code, language: .python).count
        }
        let first = counts[0]
        for count in counts { XCTAssertEqual(count, first) }
    }

    func testKeywordTokensHaveCorrectColor() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "import Foundation"
        let tokens = hl.highlight(code, language: .swift)
        let importToken = tokens.first { t in
            let s = code[t.range]
            return s == "import"
        }
        XCTAssertNotNil(importToken, "Should find 'import' token")
        XCTAssertEqual(importToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testStringTokensHaveCorrectColor() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let s = \"hello world\""
        let tokens = hl.highlight(code, language: .swift)
        let stringToken = tokens.first { t in
            code[t.range].contains("hello")
        }
        XCTAssertNotNil(stringToken, "Should find string token")
        XCTAssertEqual(stringToken?.color, ZedTheme.dark.syntaxString)
    }

    func testCommentTokensHaveCorrectColor() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "// This is a comment\nlet x = 1"
        let tokens = hl.highlight(code, language: .swift)
        let commentToken = tokens.first { t in
            code[t.range].contains("comment")
        }
        XCTAssertNotNil(commentToken, "Should find comment token")
        XCTAssertEqual(commentToken?.color, ZedTheme.dark.syntaxComment)
    }

    func testLightThemeSyntaxDiffersFromDark() {
        let darkHL = SyntaxHighlighter(theme: .dark)
        let lightHL = SyntaxHighlighter(theme: .light)
        let code = "let x = 42"
        let darkTokens = darkHL.highlight(code, language: .swift)
        let lightTokens = lightHL.highlight(code, language: .swift)
        XCTAssertEqual(darkTokens.count, lightTokens.count)
        // Colors should differ for at least one token
        if !darkTokens.isEmpty && !lightTokens.isEmpty {
            let hasColorDiff = zip(darkTokens, lightTokens).contains { dark, light in
                dark.color != light.color
            }
            XCTAssertTrue(hasColorDiff, "Light and dark themes should produce different colors")
        }
    }
}
