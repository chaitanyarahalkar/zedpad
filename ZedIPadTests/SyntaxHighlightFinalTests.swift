import XCTest
@testable import ZedIPad

final class SyntaxHighlightFinalTests: XCTestCase {

    func testAllLanguagesWithDifferentThemes() {
        let languages: [(Language, String)] = [
            (.swift, "let x: Int = 42"),
            (.python, "def foo(): return 42"),
            (.rust, "fn main() { let x: i32 = 42; }"),
            (.javascript, "const x = 42;"),
            (.typescript, "const x: number = 42;"),
            (.go, "func main() { x := 42 }"),
            (.kotlin, "fun main() { val x = 42 }"),
            (.scala, "def x = 42"),
            (.php, "<?php $x = 42; ?>"),
            (.ruby, "x = 42"),
            (.lua, "local x = 42"),
            (.c, "int x = 42;"),
            (.cpp, "int x = 42;"),
            (.sql, "SELECT 42;"),
            (.r, "x <- 42"),
            (.html, "<div class=\"x\">42</div>"),
            (.css, ".x { width: 42px; }"),
            (.bash, "x=42"),
            (.json, "{ \"x\": 42 }"),
            (.yaml, "x: 42"),
            (.markdown, "# Title\n**bold** 42"),
        ]
        for theme in ZedTheme.allCases {
            let hl = SyntaxHighlighter(theme: theme)
            for (lang, code) in languages {
                let tokens = hl.highlight(code, language: lang)
                _ = tokens // no crash, any token count is valid
            }
        }
    }

    func testTokensHaveValidRangesForAllLanguages() {
        let code = "x = 42 // comment\n\"string\""
        for lang in [Language.swift, .python, .javascript, .ruby, .go, .php, .r] {
            let hl = SyntaxHighlighter(theme: .dark)
            let tokens = hl.highlight(code, language: lang)
            for token in tokens {
                XCTAssertTrue(token.range.lowerBound <= token.range.upperBound)
                XCTAssertTrue(token.range.lowerBound >= code.startIndex)
                XCTAssertTrue(token.range.upperBound <= code.endIndex)
            }
        }
    }

    func testSyntaxHighlighterIsStateless() {
        let hl = SyntaxHighlighter(theme: .dark)
        let code = "let x = 1"
        let tokens1 = hl.highlight(code, language: .swift)
        let tokens2 = hl.highlight(code, language: .swift)
        XCTAssertEqual(tokens1.count, tokens2.count)
    }

    func testHighlightReturnsEmptyForUnknownLanguage() {
        let hl = SyntaxHighlighter(theme: .dark)
        let tokens = hl.highlight("anything", language: .unknown)
        XCTAssertTrue(tokens.isEmpty)
    }

    func testMultipleHighlightersIndependent() {
        let code = "let x = 42"
        let hl1 = SyntaxHighlighter(theme: .dark)
        let hl2 = SyntaxHighlighter(theme: .light)
        let tokens1 = hl1.highlight(code, language: .swift)
        let tokens2 = hl2.highlight(code, language: .swift)
        XCTAssertEqual(tokens1.count, tokens2.count) // same count
        // Colors may differ between themes
        if !tokens1.isEmpty && !tokens2.isEmpty {
            let allSame = zip(tokens1, tokens2).allSatisfy { $0.color == $1.color }
            XCTAssertFalse(allSame, "Dark and light themes should produce different colors")
        }
    }
}
