import XCTest
@testable import ZedIPad

final class HighlightCorrectnessTests: XCTestCase {

    func testSwiftImportIsKeyword() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "import Foundation"
        let tokens = hl.highlight(code, language: .swift)
        let importToken = tokens.first { code[$0.range] == "import" }
        XCTAssertNotNil(importToken)
        XCTAssertEqual(importToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testPythonDefIsKeyword() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "def hello(): pass"
        let tokens = hl.highlight(code, language: .python)
        let defToken = tokens.first { code[$0.range] == "def" }
        XCTAssertNotNil(defToken)
        XCTAssertEqual(defToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testRustFnIsKeyword() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "fn main() {}"
        let tokens = hl.highlight(code, language: .rust)
        let fnToken = tokens.first { code[$0.range] == "fn" }
        XCTAssertNotNil(fnToken)
        XCTAssertEqual(fnToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testGoFuncIsKeyword() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "func main() {}"
        let tokens = hl.highlight(code, language: .go)
        let funcToken = tokens.first { code[$0.range] == "func" }
        XCTAssertNotNil(funcToken)
        XCTAssertEqual(funcToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testJavaScriptConstIsKeyword() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "const x = 42;"
        let tokens = hl.highlight(code, language: .javascript)
        let constToken = tokens.first { code[$0.range] == "const" }
        XCTAssertNotNil(constToken)
        XCTAssertEqual(constToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testStringLiteralColor() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let s = \"hello\""
        let tokens = hl.highlight(code, language: .swift)
        let stringToken = tokens.first { code[$0.range].contains("hello") }
        XCTAssertNotNil(stringToken)
        XCTAssertEqual(stringToken?.color, ZedTheme.dark.syntaxString)
    }

    func testLineCommentColor() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "// this is a comment\nlet x = 1"
        let tokens = hl.highlight(code, language: .swift)
        let commentToken = tokens.first { code[$0.range].contains("comment") }
        XCTAssertNotNil(commentToken)
        XCTAssertEqual(commentToken?.color, ZedTheme.dark.syntaxComment)
    }

    func testNumberColor() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let count = 42"
        let tokens = hl.highlight(code, language: .swift)
        let numToken = tokens.first { code[$0.range] == "42" }
        XCTAssertNotNil(numToken)
        XCTAssertEqual(numToken?.color, ZedTheme.dark.syntaxNumber)
    }
}
