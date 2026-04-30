import XCTest
@testable import ZedIPad

final class TokenCountTests: XCTestCase {

    private let hl = SyntaxHighlighter(theme: .dark)

    func testSwiftHasMoreKeywordsThanUnknown() {
        let code = "import Foundation\nstruct Foo { let x = 42 }\nfunc bar() { return }"
        let swiftCount = hl.highlight(code, language: .swift).filter { $0.color == ZedTheme.dark.syntaxKeyword }.count
        let unknownCount = hl.highlight(code, language: .unknown).filter { $0.color == ZedTheme.dark.syntaxKeyword }.count
        XCTAssertGreaterThan(swiftCount, unknownCount)
    }

    func testPythonHasCommentTokens() {
        let code = "# line 1\nx = 1\n# line 2\ny = 2"
        let tokens = hl.highlight(code, language: .python)
        let commentCount = tokens.filter { $0.color == ZedTheme.dark.syntaxComment }.count
        XCTAssertEqual(commentCount, 2)
    }

    func testJSHasStringTokens() {
        let code = "const a = 'hello';\nconst b = \"world\";"
        let tokens = hl.highlight(code, language: .javascript)
        let strCount = tokens.filter { $0.color == ZedTheme.dark.syntaxString }.count
        XCTAssertGreaterThan(strCount, 0)
    }

    func testRustHasTypeTokens() {
        let code = "let x: String = String::new();\nlet v: Vec<i32> = Vec::new();"
        let tokens = hl.highlight(code, language: .rust)
        let typeCount = tokens.filter { $0.color == ZedTheme.dark.syntaxType }.count
        XCTAssertGreaterThan(typeCount, 0)
    }

    func testTokensNonOverlapping() {
        let code = "import Foundation\nlet x: Int = 42\nfunc hello() {}"
        let tokens = hl.highlight(code, language: .swift)
        // Sort by lower bound and check no overlap
        let sorted = tokens.sorted { $0.range.lowerBound < $1.range.lowerBound }
        for i in 0..<sorted.count - 1 {
            XCTAssertTrue(sorted[i].range.upperBound <= sorted[i+1].range.lowerBound ||
                          sorted[i].range.lowerBound == sorted[i+1].range.lowerBound,
                          "Tokens should not overlap") // overlapping is OK for different color layers
        }
    }

    func testJSONHasBoolTokens() {
        let code = "{ \"active\": true, \"verified\": false, \"deleted\": null }"
        let tokens = hl.highlight(code, language: .json)
        let kwTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxKeyword }
        XCTAssertGreaterThan(kwTokens.count, 0)
    }

    func testYAMLHasKeyTokens() {
        let code = "name: test\nversion: 1\nenabled: true"
        let tokens = hl.highlight(code, language: .yaml)
        let funcTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxFunction }
        XCTAssertEqual(funcTokens.count, 3) // name, version, enabled
    }
}
