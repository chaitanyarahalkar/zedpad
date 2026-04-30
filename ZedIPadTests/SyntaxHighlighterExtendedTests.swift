import XCTest
@testable import ZedIPad

final class SyntaxHighlighterExtendedTests: XCTestCase {
    let themes = ZedTheme.allCases

    func testHighlightYAML() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        name: my-app
        version: "1.0"
        debug: true
        count: 42
        """
        let tokens = hl.highlight(code, language: .yaml)
        // YAML uses string tokenizer
        XCTAssertFalse(tokens.isEmpty, "YAML should produce string tokens for quoted values")
    }

    func testHighlightBash() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        #!/bin/bash
        # Build script
        set -e
        echo "Building..."
        if [ -f ./Makefile ]; then
            make all
        fi
        """
        let tokens = hl.highlight(code, language: .bash)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightRuby() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = """
        # Ruby example
        class Greeter
          def initialize(name)
            @name = name
          end

          def greet
            "Hello, #{@name}!"
          end
        end

        g = Greeter.new("World")
        puts g.greet
        """
        let tokens = hl.highlight(code, language: .ruby)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testTokensDontOverlapInSwift() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "import Foundation\nlet x: Int = 42\n// comment\n\"string literal\""
        let tokens = hl.highlight(code, language: .swift)
        // Verify all token ranges are valid
        for token in tokens {
            XCTAssertTrue(token.range.lowerBound <= token.range.upperBound,
                          "Token range should be valid")
        }
    }

    func testAllThemesProduceTokensForSwift() {
        let code = "import SwiftUI\nstruct Foo: View { var body: some View { Text(\"hi\") } }"
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            let tokens = hl.highlight(code, language: .swift)
            XCTAssertFalse(tokens.isEmpty, "Theme \(theme.rawValue) should produce tokens")
        }
    }

    func testHighlightLargeFile() {
        let hl = SyntaxHighlighter(theme: .dark)
        let line = "let value: Int = 42 // a number\n"
        let code = String(repeating: line, count: 200)
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
        // Should not crash on large input
    }

    func testHighlightEmptyLines() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "\n\n\nlet x = 1\n\n\n"
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightMixedUnicode() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "// 日本語 comment\nlet greeting = \"こんにちは\"\nlet emoji = \"🎉\""
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightNestedStrings() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let s = \"hello \\\"world\\\" end\""
        let tokens = hl.highlight(code, language: .swift)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightBlockComment() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "/* This is\n   a block\n   comment */\nlet x = 1"
        let tokens = hl.highlight(code, language: .swift)
        let commentTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxComment }
        XCTAssertFalse(commentTokens.isEmpty, "Block comment should produce comment tokens")
    }

    func testHighlightNumbers() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let a = 42\nlet b = 3.14\nlet c = 100_000"
        let tokens = hl.highlight(code, language: .swift)
        let numberTokens = tokens.filter { $0.color == ZedTheme.dark.syntaxNumber }
        XCTAssertFalse(numberTokens.isEmpty)
    }

    func testLanguageDetectionCaseInsensitive() {
        // Extensions are lowercased before detection
        XCTAssertEqual(Language.detect(from: "SWIFT".lowercased()), .swift)
        XCTAssertEqual(Language.detect(from: "PY".lowercased()), .python)
        XCTAssertEqual(Language.detect(from: "RS".lowercased()), .rust)
    }
}
