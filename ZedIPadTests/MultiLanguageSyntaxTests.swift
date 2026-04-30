import XCTest
@testable import ZedIPad

final class MultiLanguageSyntaxTests: XCTestCase {
    private let hl = SyntaxHighlighter(theme: .dark)

    func testSameStringLiteralColorAcrossLanguages() {
        let stringLiteralCode = "\"hello world\""
        let languagesWithStrings: [Language] = [.swift, .python, .javascript, .go, .rust, .kotlin, .php, .ruby]
        for lang in languagesWithStrings {
            let tokens = hl.highlight(stringLiteralCode, language: lang)
            let strToken = tokens.first { stringLiteralCode[$0.range].contains("hello") }
            if let token = strToken {
                XCTAssertEqual(token.color, ZedTheme.dark.syntaxString,
                               "String in \(lang) should use syntaxString color")
            }
        }
    }

    func testBlockCommentSyntaxAcrossLanguages() {
        let blockComment = "/* This is a block comment */"
        let languages: [Language] = [.swift, .javascript, .go, .rust, .kotlin, .c, .cpp, .java ?? .unknown]
        let actualLangs: [Language] = [.swift, .javascript, .go, .rust, .kotlin, .c, .cpp]
        for lang in actualLangs {
            let tokens = hl.highlight(blockComment, language: lang)
            let commentToken = tokens.first { blockComment[$0.range].contains("block comment") }
            XCTAssertNotNil(commentToken, "Block comment not found for \(lang)")
            XCTAssertEqual(commentToken?.color, ZedTheme.dark.syntaxComment,
                           "Block comment in \(lang) should use syntaxComment color")
        }
    }

    func testNumberLiteralAcrossLanguages() {
        let numCode = "x = 42"
        let languagesWithNums: [Language] = [.swift, .python, .javascript, .go, .rust, .kotlin, .php, .ruby, .lua, .scala]
        for lang in languagesWithNums {
            let tokens = hl.highlight(numCode, language: lang)
            let numToken = tokens.first { numCode[$0.range] == "42" }
            XCTAssertNotNil(numToken, "Number 42 not highlighted in \(lang)")
            XCTAssertEqual(numToken?.color, ZedTheme.dark.syntaxNumber,
                           "Number 42 in \(lang) should use syntaxNumber color")
        }
    }

    func testHashCommentInMultipleLanguages() {
        let hashComment = "# This is a comment"
        let languages: [Language] = [.python, .bash, .ruby, .r]
        for lang in languages {
            let tokens = hl.highlight(hashComment, language: lang)
            let commentToken = tokens.first { hashComment[$0.range].contains("comment") }
            XCTAssertNotNil(commentToken, "Hash comment not found for \(lang)")
        }
    }
}

// Avoid force-unwrapping
extension Language {
    static var java: Language? { return nil } // Java not supported, placeholder
}
