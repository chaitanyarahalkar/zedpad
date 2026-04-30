import XCTest
@testable import ZedIPad

final class TokenRangeTests: XCTestCase {

    private func assertValidTokens(_ tokens: [SyntaxToken], in text: String, file: StaticString = #file, line: UInt = #line) {
        for token in tokens {
            XCTAssertTrue(token.range.lowerBound >= text.startIndex,
                          "Token start out of bounds", file: file, line: line)
            XCTAssertTrue(token.range.upperBound <= text.endIndex,
                          "Token end out of bounds", file: file, line: line)
            XCTAssertTrue(token.range.lowerBound <= token.range.upperBound,
                          "Token inverted range", file: file, line: line)
        }
    }

    func testSwiftTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "import Foundation\nstruct Foo: Equatable { let x: Int = 42 }"
        let tokens = hl.highlight(code, language: .swift)
        assertValidTokens(tokens, in: code)
    }

    func testPythonTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "def add(a, b):\n    # Add two numbers\n    return a + b\n\nresult = add(3, 4)"
        let tokens = hl.highlight(code, language: .python)
        assertValidTokens(tokens, in: code)
    }

    func testRustTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "fn factorial(n: u64) -> u64 {\n    if n <= 1 { return 1; }\n    n * factorial(n - 1)\n}"
        let tokens = hl.highlight(code, language: .rust)
        assertValidTokens(tokens, in: code)
    }

    func testHTMLTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "<html><head><title>Test</title></head><body><!-- comment --></body></html>"
        let tokens = hl.highlight(code, language: .html)
        assertValidTokens(tokens, in: code)
    }

    func testCSSTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = ".container { width: 100%; margin: 0 auto; background-color: #fff; }"
        let tokens = hl.highlight(code, language: .css)
        assertValidTokens(tokens, in: code)
    }

    func testSQLTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "SELECT id, name FROM users WHERE active = TRUE ORDER BY id DESC LIMIT 10;"
        let tokens = hl.highlight(code, language: .sql)
        assertValidTokens(tokens, in: code)
    }

    func testGoTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "package main\nimport \"fmt\"\nfunc main() {\n    fmt.Println(\"Hello, World!\")\n}"
        let tokens = hl.highlight(code, language: .go)
        assertValidTokens(tokens, in: code)
    }

    func testPHPTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "<?php\n$name = \"World\";\necho \"Hello, $name!\";\n?>"
        let tokens = hl.highlight(code, language: .php)
        assertValidTokens(tokens, in: code)
    }

    func testRubyTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "class Dog\n  def initialize(name)\n    @name = name\n  end\n  def bark\n    \"Woof!\"\n  end\nend"
        let tokens = hl.highlight(code, language: .ruby)
        assertValidTokens(tokens, in: code)
    }

    func testCppTokenRangesValid() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "#include <vector>\ntemplate<typename T>\nT sum(const std::vector<T>& v) {\n    T result = 0;\n    for (auto& x : v) result += x;\n    return result;\n}"
        let tokens = hl.highlight(code, language: .cpp)
        assertValidTokens(tokens, in: code)
    }
}
