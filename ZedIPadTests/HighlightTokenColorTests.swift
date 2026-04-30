import XCTest
@testable import ZedIPad

final class HighlightTokenColorTests: XCTestCase {

    func testDarkAndLightHaveDifferentKeywordColors() {
        XCTAssertNotEqual(ZedTheme.dark.syntaxKeyword, ZedTheme.light.syntaxKeyword)
    }

    func testOneDarkAndSolarizedHaveDifferentKeywords() {
        XCTAssertNotEqual(ZedTheme.oneDark.syntaxKeyword, ZedTheme.solarizedDark.syntaxKeyword)
    }

    func testStringColorsDifferFromCommentColors() {
        for theme in ZedTheme.allCases {
            XCTAssertNotEqual(theme.syntaxString, theme.syntaxComment,
                              "\(theme.rawValue) string and comment should differ")
        }
    }

    func testNumberColorsDifferFromKeywordColors() {
        for theme in ZedTheme.allCases {
            XCTAssertNotEqual(theme.syntaxNumber, theme.syntaxKeyword,
                              "\(theme.rawValue) number and keyword should differ")
        }
    }

    func testFunctionColorDistinctFromTypeColor() {
        for theme in ZedTheme.allCases {
            XCTAssertNotEqual(theme.syntaxFunction, theme.syntaxType,
                              "\(theme.rawValue) function and type should differ")
        }
    }

    func testHighlightProducesExpectedColorForSwiftKeyword() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "return true"
        let tokens = hl.highlight(code, language: .swift)
        let returnToken = tokens.first { code[$0.range] == "return" }
        XCTAssertNotNil(returnToken)
        XCTAssertEqual(returnToken?.color, ZedTheme.dark.syntaxKeyword)
    }

    func testHighlightProducesExpectedColorForNumber() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let x = 100"
        let tokens = hl.highlight(code, language: .swift)
        let numToken = tokens.first { code[$0.range] == "100" }
        XCTAssertNotNil(numToken)
        XCTAssertEqual(numToken?.color, ZedTheme.dark.syntaxNumber)
    }

    func testHighlightProducesExpectedColorForString() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let s = \"hello\""
        let tokens = hl.highlight(code, language: .swift)
        let strToken = tokens.first { code[$0.range].contains("hello") }
        XCTAssertNotNil(strToken)
        XCTAssertEqual(strToken?.color, ZedTheme.dark.syntaxString)
    }
}
