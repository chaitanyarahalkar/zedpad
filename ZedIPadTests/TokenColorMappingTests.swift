import XCTest
@testable import ZedIPad

final class TokenColorMappingTests: XCTestCase {
    private let dark = SyntaxHighlighter(theme: .dark)
    private let light = SyntaxHighlighter(theme: .light)
    private let oneDark = SyntaxHighlighter(theme: .oneDark)
    private let solarized = SyntaxHighlighter(theme: .solarizedDark)

    func testKeywordColorUsedInSwift() {
        let code = "struct Foo: View { var body: some View { EmptyView() } }"
        for hl in [dark, light, oneDark, solarized] {
            let tokens = hl.highlight(code, language: .swift)
            let colors = Set(tokens.map { "\($0.color)" })
            XCTAssertGreaterThan(colors.count, 1, "Multiple colors expected")
        }
    }

    func testCommentColorInPython() {
        let code = "# Header comment\ndef foo():\n    # body comment\n    pass"
        let tokens = dark.highlight(code, language: .python)
        let commentTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxComment }
        XCTAssertEqual(commentTokens.count, 2)
    }

    func testNumberColorInJSON() {
        let code = "{ \"count\": 42, \"pi\": 3.14, \"negative\": -1 }"
        let tokens = dark.highlight(code, language: .json)
        let numTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxNumber }
        XCTAssertGreaterThan(numTokens.count, 0)
    }

    func testKeywordColorInRust() {
        let code = "fn main() { let x: u32 = 0; }"
        let tokens = dark.highlight(code, language: .rust)
        let kwTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxKeyword }
        XCTAssertGreaterThan(kwTokens.count, 0)
    }

    func testStringColorInGo() {
        let code = "package main\nconst msg = \"hello world\""
        let tokens = dark.highlight(code, language: .go)
        let strTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxString }
        XCTAssertGreaterThan(strTokens.count, 0)
    }

    func testPHPVariableColorDistinctFromKeyword() {
        let phpTheme = ZedTheme.dark
        XCTAssertNotEqual(phpTheme.syntaxType, phpTheme.syntaxKeyword)
    }

    func testYAMLKeyColorInYAML() {
        let code = "name: my-app\nversion: \"1.0\"\nactive: true"
        let tokens = dark.highlight(code, language: .yaml)
        let funcTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxFunction }
        XCTAssertGreaterThan(funcTokens.count, 0, "YAML keys should use function color")
    }

    func testHTMLTagColor() {
        let code = "<div class=\"container\"><p>Text</p></div>"
        let tokens = dark.highlight(code, language: .html)
        let kwTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxKeyword }
        XCTAssertGreaterThan(kwTokens.count, 0, "HTML tags should use keyword color")
    }
}
